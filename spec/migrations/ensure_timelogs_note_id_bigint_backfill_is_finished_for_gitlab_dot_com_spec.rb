# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnsureTimelogsNoteIdBigintBackfillIsFinishedForGitlabDotCom, feature_category: :database do
  describe '#up' do
    using RSpec::Parameterized::TableSyntax

    let(:migration_arguments) do
      {
        job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
        table_name: 'timelogs',
        column_name: 'id',
        job_arguments: [['note_id'], ['note_id_convert_to_bigint']]
      }
    end

    it 'ensures the migration is completed for GitLab.com, dev, or test' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:com_or_dev_or_test_but_not_jh?).and_return(true)
        expect(instance).to receive(:ensure_batched_background_migration_is_finished).with(migration_arguments)
      end

      migrate!
    end

    it 'skips the check for other instances' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        expect(instance).not_to receive(:ensure_batched_background_migration_is_finished)
      end

      migrate!
    end
  end
end
