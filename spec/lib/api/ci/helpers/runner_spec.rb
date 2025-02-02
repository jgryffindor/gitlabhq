# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Helpers::Runner do
  let(:helper) { Class.new { include API::Ci::Helpers::Runner }.new }

  before do
    allow(helper).to receive(:env).and_return({})
  end

  describe '#current_job', feature_category: :continuous_integration do
    let(:build) { create(:ci_build, :running) }

    it 'handles sticking of a build when a build ID is specified' do
      allow(helper).to receive(:params).and_return(id: build.id)

      expect(Ci::Build.sticking)
        .to receive(:stick_or_unstick_request)
        .with({}, :build, build.id)

      helper.current_job
    end

    it 'does not handle sticking if no build ID was specified' do
      allow(helper).to receive(:params).and_return({})

      expect(Ci::Build.sticking)
        .not_to receive(:stick_or_unstick_request)

      helper.current_job
    end

    it 'returns the build if one could be found' do
      allow(helper).to receive(:params).and_return(id: build.id)

      expect(helper.current_job).to eq(build)
    end
  end

  describe '#current_runner', feature_category: :runner do
    let(:runner) { create(:ci_runner, token: 'foo') }

    it 'handles sticking of a runner if a token is specified' do
      allow(helper).to receive(:params).and_return(token: runner.token)

      expect(Ci::Runner.sticking)
        .to receive(:stick_or_unstick_request)
        .with({}, :runner, runner.token)

      helper.current_runner
    end

    it 'does not handle sticking if no token was specified' do
      allow(helper).to receive(:params).and_return({})

      expect(Ci::Runner.sticking)
        .not_to receive(:stick_or_unstick_request)

      helper.current_runner
    end

    it 'returns the runner if one could be found' do
      allow(helper).to receive(:params).and_return(token: runner.token)

      expect(helper.current_runner).to eq(runner)
    end
  end

  describe '#current_runner_machine', :freeze_time, feature_category: :runner_fleet do
    let(:runner) { create(:ci_runner, token: 'foo') }
    let(:runner_machine) { create(:ci_runner_machine, runner: runner, system_xid: 'bar', contacted_at: 1.hour.ago) }

    subject(:current_runner_machine) { helper.current_runner_machine }

    context 'with create_runner_machine FF enabled' do
      before do
        stub_feature_flags(create_runner_machine: true)
      end

      context 'when runner machine already exists' do
        before do
          allow(helper).to receive(:params).and_return(token: runner.token, system_id: runner_machine.system_xid)
        end

        it { is_expected.to eq(runner_machine) }

        it 'does not update the contacted_at field' do
          expect(current_runner_machine.contacted_at).to eq 1.hour.ago
        end
      end

      context 'when runner machine cannot be found' do
        it 'creates a new runner machine', :aggregate_failures do
          allow(helper).to receive(:params).and_return(token: runner.token, system_id: 'new_system_id')

          expect { current_runner_machine }.to change { Ci::RunnerMachine.count }.by(1)

          expect(current_runner_machine).not_to be_nil
          expect(current_runner_machine.system_xid).to eq('new_system_id')
          expect(current_runner_machine.contacted_at).to eq(Time.current)
          expect(current_runner_machine.runner).to eq(runner)
        end

        it 'creates a new <legacy> runner machine if system_id is not specified', :aggregate_failures do
          allow(helper).to receive(:params).and_return(token: runner.token)

          expect { current_runner_machine }.to change { Ci::RunnerMachine.count }.by(1)

          expect(current_runner_machine).not_to be_nil
          expect(current_runner_machine.system_xid).to eq(::API::Ci::Helpers::Runner::LEGACY_SYSTEM_XID)
          expect(current_runner_machine.runner).to eq(runner)
        end
      end
    end

    context 'with create_runner_machine FF disabled' do
      before do
        stub_feature_flags(create_runner_machine: false)
      end

      it 'does not return runner machine if no system_id specified' do
        allow(helper).to receive(:params).and_return(token: runner.token)

        is_expected.to be_nil
      end

      context 'when runner machine can not be found' do
        before do
          allow(helper).to receive(:params).and_return(token: runner.token, system_id: 'new_system_id')
        end

        it 'does not create a new runner machine', :aggregate_failures do
          expect { current_runner_machine }.not_to change { Ci::RunnerMachine.count }

          expect(current_runner_machine).to be_nil
        end
      end
    end
  end

  describe '#track_runner_authentication', :prometheus, feature_category: :runner do
    subject { helper.track_runner_authentication }

    let(:runner) { create(:ci_runner, token: 'foo') }

    it 'increments gitlab_ci_runner_authentication_success_total' do
      allow(helper).to receive(:params).and_return(token: runner.token)

      success_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_success_counter
      failure_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_failure_counter
      expect { subject }.to change { success_counter.get(runner_type: 'instance_type') }.by(1)
        .and not_change { success_counter.get(runner_type: 'project_type') }
        .and not_change { failure_counter.get }
    end

    it 'increments gitlab_ci_runner_authentication_failure_total' do
      allow(helper).to receive(:params).and_return(token: 'invalid')

      success_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_success_counter
      failure_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_failure_counter
      expect { subject }.to change { failure_counter.get }.by(1)
        .and not_change { success_counter.get(runner_type: 'instance_type') }
        .and not_change { success_counter.get(runner_type: 'project_type') }
    end
  end
end
