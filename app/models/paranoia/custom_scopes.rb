
module Paranoia
  module CustomScopes
    extend ActiveSupport::Concern

    module ClassMethods
      def default_scope
        scoped.with_deleted
      end

      def without_deleted
        scoped.where("#{self.table_name}.deleted_at is null")
      end
    end

  end
end
