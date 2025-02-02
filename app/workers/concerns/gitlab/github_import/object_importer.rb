# frozen_string_literal: true

module Gitlab
  module GithubImport
    # ObjectImporter defines the base behaviour for every Sidekiq worker that
    # imports a single resource such as a note or pull request.
    module ObjectImporter
      extend ActiveSupport::Concern

      included do
        include ApplicationWorker

        sidekiq_options retry: 3
        include GithubImport::Queue
        include ReschedulingMethods

        feature_category :importers
        worker_has_external_dependencies!

        sidekiq_retries_exhausted do |msg|
          args = msg['args']
          correlation_id = msg['correlation_id']
          jid = msg['jid']

          new.perform_failure(args[0], args[1], correlation_id)

          # If a job is being exhausted we still want to notify the
          # Gitlab::Import::AdvanceStageWorker to prevent the entire import from getting stuck
          if args.length == 3 && (key = args.last) && key.is_a?(String)
            JobWaiter.notify(key, jid)
          end
        end
      end

      NotRetriableError = Class.new(StandardError)

      # project - An instance of `Project` to import the data into.
      # client - An instance of `Gitlab::GithubImport::Client`
      # hash - A Hash containing the details of the object to import.
      def import(project, client, hash)
        if project.import_state&.canceled?
          info(project.id, message: 'project import canceled')

          return
        end

        object = representation_class.from_json_hash(hash)

        # To better express in the logs what object is being imported.
        self.github_identifiers = object.github_identifiers
        info(project.id, message: 'starting importer')

        importer_class.new(object, project, client).execute

        if increment_object_counter?(object)
          Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :imported)
        end

        info(project.id, message: 'importer finished')
      rescue NoMethodError => e
        # This exception will be more useful in development when a new
        # Representation is created but the developer forgot to add a
        # `:github_identifiers` field.
        track_and_raise_exception(project, e, fail_import: true)
      rescue ActiveRecord::RecordInvalid, NotRetriableError => e
        # We do not raise exception to prevent job retry
        failure = track_exception(project, e)
        add_identifiers_to_failure(failure, object.github_identifiers)
      rescue StandardError => e
        track_and_raise_exception(project, e)
      end

      # hash - A Hash containing the details of the object to import.
      def perform_failure(project_id, hash, correlation_id)
        project = Project.find_by_id(project_id)
        return unless project

        failure = project.import_failures.failures_by_correlation_id(correlation_id).first
        return unless failure

        object = representation_class.from_json_hash(hash)

        add_identifiers_to_failure(failure, object.github_identifiers)
      end

      def increment_object_counter?(_object)
        true
      end

      def object_type
        raise NotImplementedError
      end

      # Returns the representation class to use for the object. This class must
      # define the class method `from_json_hash`.
      def representation_class
        raise NotImplementedError
      end

      # Returns the class to use for importing the object.
      def importer_class
        raise NotImplementedError
      end

      private

      attr_accessor :github_identifiers

      def info(project_id, extra = {})
        Logger.info(log_attributes(project_id, extra))
      end

      def log_attributes(project_id, extra = {})
        extra.merge(
          project_id: project_id,
          importer: importer_class.name,
          github_identifiers: github_identifiers
        )
      end

      def track_exception(project, exception, fail_import: false)
        Gitlab::Import::ImportFailureService.track(
          project_id: project.id,
          error_source: importer_class.name,
          exception: exception,
          fail_import: fail_import
        )
      end

      def track_and_raise_exception(project, exception, fail_import: false)
        track_exception(project, exception, fail_import: fail_import)

        raise(exception)
      end

      def add_identifiers_to_failure(failure, external_identifiers)
        failure.update_column(:external_identifiers, external_identifiers)
      end
    end
  end
end
