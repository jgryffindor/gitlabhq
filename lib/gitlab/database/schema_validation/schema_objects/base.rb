# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module SchemaObjects
        class Base
          def initialize(parsed_stmt)
            @parsed_stmt = parsed_stmt
          end

          def name
            raise NoMethodError, "subclasses of #{self.class.name} must implement #{__method__}"
          end

          def statement
            @statement ||= PgQuery.deparse_stmt(parsed_stmt)
          end

          private

          attr_reader :parsed_stmt
        end
      end
    end
  end
end
