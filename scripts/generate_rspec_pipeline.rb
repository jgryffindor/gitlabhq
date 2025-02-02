#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'
require 'json'
require 'fileutils'
require 'erb'
require_relative '../tooling/quality/test_level'

# Class to generate RSpec test child pipeline with dynamically parallelized jobs.
class GenerateRspecPipeline
  SKIP_PIPELINE_YML_FILE = ".gitlab/ci/_skip.yml"
  TEST_LEVELS = %i[migration background_migration unit integration system].freeze
  MAX_NODES_COUNT = 50 # Maximum parallelization allowed by GitLab

  OPTIMAL_TEST_JOB_DURATION_IN_SECONDS = 600 # 10 MINUTES
  SETUP_DURATION_IN_SECONDS = 180.0 # 3 MINUTES
  OPTIMAL_TEST_RUNTIME_DURATION_IN_SECONDS = OPTIMAL_TEST_JOB_DURATION_IN_SECONDS - SETUP_DURATION_IN_SECONDS

  # As of 2022-09-01:
  # $ find spec -type f | wc -l
  #  12825
  # and
  # $ find ee/spec -type f | wc -l
  #  5610
  # which gives a total of 18435 test files (`NUMBER_OF_TESTS_IN_TOTAL_IN_THE_TEST_SUITE`).
  #
  # Total time to run all tests (based on https://gitlab-org.gitlab.io/rspec_profiling_stats/)
  # is 170183 seconds (`DURATION_OF_THE_TEST_SUITE_IN_SECONDS`).
  #
  # This gives an approximate 170183 / 18435 = 9.2 seconds per test file
  # (`DEFAULT_AVERAGE_TEST_FILE_DURATION_IN_SECONDS`).
  #
  # If we want each test job to finish in 10 minutes, given we have 3 minutes of setup (`SETUP_DURATION_IN_SECONDS`),
  # then we need to give 7 minutes of testing to each test node (`OPTIMAL_TEST_RUNTIME_DURATION_IN_SECONDS`).
  # (7 * 60) / 9.2 = 45.6
  #
  # So if we'd want to run the full test suites in 10 minutes (`OPTIMAL_TEST_JOB_DURATION_IN_SECONDS`),
  # we'd need to run at max 45 test file per nodes (`#optimal_test_file_count_per_node_per_test_level`).
  NUMBER_OF_TESTS_IN_TOTAL_IN_THE_TEST_SUITE = 18_435
  DURATION_OF_THE_TEST_SUITE_IN_SECONDS = 170_183
  DEFAULT_AVERAGE_TEST_FILE_DURATION_IN_SECONDS =
    DURATION_OF_THE_TEST_SUITE_IN_SECONDS / NUMBER_OF_TESTS_IN_TOTAL_IN_THE_TEST_SUITE

  # rspec_files_path: A file containing RSpec files to run, separated by a space
  # pipeline_template_path: A YAML pipeline configuration template to generate the final pipeline config from
  def initialize(pipeline_template_path:, rspec_files_path: nil, knapsack_report_path: nil)
    @pipeline_template_path = pipeline_template_path.to_s
    @rspec_files_path = rspec_files_path.to_s
    @knapsack_report_path = knapsack_report_path.to_s

    raise ArgumentError unless File.exist?(@pipeline_template_path)
  end

  def generate!
    if all_rspec_files.empty?
      info "Using #{SKIP_PIPELINE_YML_FILE} due to no RSpec files to run"
      FileUtils.cp(SKIP_PIPELINE_YML_FILE, pipeline_filename)
      return
    end

    File.open(pipeline_filename, 'w') do |handle|
      pipeline_yaml = ERB.new(File.read(pipeline_template_path)).result_with_hash(**erb_binding)
      handle.write(pipeline_yaml.squeeze("\n").strip)
    end
  end

  private

  attr_reader :pipeline_template_path, :rspec_files_path, :knapsack_report_path

  def info(text)
    $stdout.puts "[#{self.class.name}] #{text}"
  end

  def all_rspec_files
    @all_rspec_files ||= File.exist?(rspec_files_path) ? File.read(rspec_files_path).split(' ') : []
  end

  def pipeline_filename
    @pipeline_filename ||= "#{pipeline_template_path}.yml"
  end

  def erb_binding
    { rspec_files_per_test_level: rspec_files_per_test_level }
  end

  def rspec_files_per_test_level
    @rspec_files_per_test_level ||= begin
      all_remaining_rspec_files = all_rspec_files.dup
      TEST_LEVELS.each_with_object(Hash.new { |h, k| h[k] = {} }) do |test_level, memo| # rubocop:disable Rails/IndexWith
        memo[test_level][:files] = all_remaining_rspec_files
          .grep(Quality::TestLevel.new.regexp(test_level))
          .tap { |files| files.each { |file| all_remaining_rspec_files.delete(file) } }
        memo[test_level][:parallelization] = optimal_nodes_count(test_level, memo[test_level][:files])
      end
    end
  end

  def optimal_nodes_count(test_level, rspec_files)
    nodes_count = (rspec_files.size / optimal_test_file_count_per_node_per_test_level(test_level)).ceil
    info "Optimal node count for #{rspec_files.size} #{test_level} RSpec files is #{nodes_count}."

    if nodes_count > MAX_NODES_COUNT
      info "We don't want to parallelize to more than #{MAX_NODES_COUNT} jobs for now! " \
           "Decreasing the parallelization to #{MAX_NODES_COUNT}."

      MAX_NODES_COUNT
    else
      nodes_count
    end
  end

  def optimal_test_file_count_per_node_per_test_level(test_level)
    [
      (OPTIMAL_TEST_RUNTIME_DURATION_IN_SECONDS / average_test_file_duration_in_seconds_per_test_level[test_level]),
      1
    ].max
  end

  def average_test_file_duration_in_seconds_per_test_level
    @optimal_test_file_count_per_node_per_test_level ||=
      if knapsack_report.any?
        remaining_knapsack_report = knapsack_report.dup
        TEST_LEVELS.each_with_object({}) do |test_level, memo|
          matching_data_per_test_level = remaining_knapsack_report
            .select { |test_file, _| test_file.match?(Quality::TestLevel.new.regexp(test_level)) }
            .tap { |test_data| test_data.each { |file, _| remaining_knapsack_report.delete(file) } }
          memo[test_level] =
            matching_data_per_test_level.values.sum / matching_data_per_test_level.keys.size
        end
      else
        TEST_LEVELS.each_with_object({}) do |test_level, memo| # rubocop:disable Rails/IndexWith
          memo[test_level] = DEFAULT_AVERAGE_TEST_FILE_DURATION_IN_SECONDS
        end
      end
  end

  def knapsack_report
    @knapsack_report ||=
      begin
        File.exist?(knapsack_report_path) ? JSON.parse(File.read(knapsack_report_path)) : {}
      rescue JSON::ParserError => e
        info "[ERROR] Knapsack report at #{knapsack_report_path} couldn't be parsed! Error:\n#{e}"
        {}
      end
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}

  OptionParser.new do |opts|
    opts.on("-f", "--rspec-files-path path", String, "Path to a file containing RSpec files to run, " \
                                                     "separated by a space") do |value|
      options[:rspec_files_path] = value
    end

    opts.on("-t", "--pipeline-template-path PATH", String, "Path to a YAML pipeline configuration template to " \
                                                           "generate the final pipeline config from") do |value|
      options[:pipeline_template_path] = value
    end

    opts.on("-k", "--knapsack-report-path path", String, "Path to a Knapsack report") do |value|
      options[:knapsack_report_path] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  GenerateRspecPipeline.new(**options).generate!
end
