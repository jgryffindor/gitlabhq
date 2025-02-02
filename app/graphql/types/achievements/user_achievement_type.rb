# frozen_string_literal: true

module Types
  module Achievements
    class UserAchievementType < BaseObject
      graphql_name 'UserAchievement'

      authorize :read_achievement

      field :id,
        ::Types::GlobalIDType[::Achievements::UserAchievement],
        null: false,
        description: 'ID of the user achievement.'

      field :achievement,
        ::Types::Achievements::AchievementType,
        null: false,
        description: 'Achievement awarded.'

      field :user,
        ::Types::UserType,
        null: false,
        description: 'Achievement recipient.'

      field :awarded_by_user,
        ::Types::UserType,
        null: false,
        description: 'Awarded by.'

      field :revoked_by_user,
        ::Types::UserType,
        null: true,
        description: 'Revoked by.'

      field :created_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp the achievement was created.'

      field :updated_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp the achievement was last updated.'

      field :revoked_at,
        Types::TimeType,
        null: true,
        description: 'Timestamp the achievement was revoked.'
    end
  end
end
