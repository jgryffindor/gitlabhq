# frozen_string_literal: true

# Tracks egress of various services per project
# This class ensures that we keep 1 record per project per month.
module Projects
  class DataTransfer < ApplicationRecord
    include AfterCommitQueue
    include CounterAttribute

    self.table_name = 'project_data_transfers'

    belongs_to :project
    belongs_to :namespace

    scope :current_month, -> { where(date: beginning_of_month) }

    counter_attribute :repository_egress, returns_current: true
    counter_attribute :artifacts_egress, returns_current: true
    counter_attribute :packages_egress, returns_current: true
    counter_attribute :registry_egress, returns_current: true

    def self.beginning_of_month(time = Time.current)
      time.utc.beginning_of_month
    end
  end
end
