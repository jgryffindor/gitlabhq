# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe FinalizeNullifyCreatorIdOfOrphanedProjects, :migration, feature_category: :projects do
  let(:batched_migrations) { table(:batched_background_migrations) }
  let(:batch_failed_status) { 2 }
  let(:batch_finalized_status) { 3 }

  let!(:migration) { described_class::MIGRATION }

  describe '#up' do
    shared_examples 'finalizes the migration' do
      it 'finalizes the migration' do
        expect do
          migrate!

          migration_record.reload
          failed_job.reload
        end.to change { migration_record.status }.from(migration_record.status).to(3).and(
          change { failed_job.status }.from(batch_failed_status).to(batch_finalized_status)
        )
      end
    end

    context 'when migration is missing' do
      it 'warns migration not found' do
        expect(Gitlab::AppLogger)
          .to receive(:warn).with(/Could not find batched background migration for the given configuration:/)

        migrate!
      end
    end

    context 'with migration present' do
      let!(:migration_record) do
        batched_migrations.create!(
          job_class_name: 'NullifyCreatorIdColumnOfOrphanedProjects',
          table_name: :projects,
          column_name: :id,
          job_arguments: [],
          interval: 2.minutes,
          min_value: 1,
          max_value: 2,
          batch_size: 1000,
          sub_batch_size: 500,
          max_batch_size: 5000,
          gitlab_schema: :gitlab_main,
          status: 3 # finished
        )
      end

      context 'when migration finished successfully' do
        it 'does not raise exception' do
          expect { migrate! }.not_to raise_error
        end
      end

      context 'with different migration statuses', :redis do
        using RSpec::Parameterized::TableSyntax

        where(:status, :description) do
          0 | 'paused'
          1 | 'active'
          4 | 'failed'
          5 | 'finalizing'
        end

        with_them do
          let!(:failed_job) do
            table(:batched_background_migration_jobs).create!(
              batched_background_migration_id: migration_record.id,
              status: batch_failed_status,
              min_value: 1,
              max_value: 10,
              attempts: 2,
              batch_size: 100,
              sub_batch_size: 10
            )
          end

          before do
            migration_record.update!(status: status)
          end

          it_behaves_like 'finalizes the migration'
        end
      end
    end
  end
end
