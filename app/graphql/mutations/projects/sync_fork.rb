# frozen_string_literal: true

module Mutations
  module Projects
    class SyncFork < BaseMutation
      graphql_name 'ProjectSyncFork'

      include FindsProject

      authorize :push_code

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path of the project to initialize.'

      argument :target_branch, GraphQL::Types::String,
        required: true,
        description: 'Ref of the fork to fetch into.'

      field :details, Types::Projects::ForkDetailsType,
        null: true,
        description: 'Updated fork details.'

      def resolve(project_path:, target_branch:)
        project = authorized_find!(project_path)

        return respond(nil, ['Feature flag is disabled']) unless Feature.enabled?(:synchronize_fork, project)

        details_resolver = Resolvers::Projects::ForkDetailsResolver.new(object: project, context: context, field: nil)
        details = details_resolver.resolve(ref: target_branch)

        return respond(nil, ['This branch of this project cannot be updated from the upstream']) unless details

        enqueue_sync_fork(project, target_branch, details)
      end

      def enqueue_sync_fork(project, target_branch, details)
        return respond(details, []) if details.counts[:behind] == 0

        if details.has_conflicts?
          return respond(details, ['The synchronization cannot happen due to the merge conflict'])
        end

        return respond(details, ['This service has been called too many times.']) if rate_limit_throttled?(project)
        return respond(details, ['Another fork sync is already in progress']) unless details.exclusive_lease.try_obtain

        ::Projects::Forks::SyncWorker.perform_async(project.id, current_user.id, target_branch) # rubocop:disable CodeReuse/Worker

        respond(details, [])
      end

      def rate_limit_throttled?(project)
        Gitlab::ApplicationRateLimiter.throttled?(:project_fork_sync, scope: [project, current_user])
      end

      def respond(details, errors)
        { details: details, errors: errors }
      end
    end
  end
end
