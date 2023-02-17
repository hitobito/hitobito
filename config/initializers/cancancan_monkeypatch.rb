# cancancan < 3.2 is not fully compatible with rails >= 6.1
#
# Cancan >= 3.2.0 is incompatible with our class_side abilities on events
#
# In 3.2.0, cancan introduced better support for STI models:
# https://github.com/CanCanCommunity/cancancan/pull/649
#
# Unfortunately, this breaks our class_side ability DSL on STI models.
# With these changes, the class_side Event::Course rules also take effect
# when querying can?(:something, Event), which is not the way it used to
# be.
#
# To fix the incompatibility of cancancan < 3.2, we monkey patch
# `CanCan::ModelAdapters::ActiveRecord5Adapter#sanitize_sql_activerecord5`
# with the method code from cancancan 3.2
#
# We only apply the monkey patch, if we can find the patched method, and cancancan version is < 3.2
#
module CancancanMonkeypatch
  class << self

    def apply_patch
      const = find_const
      mtd = find_method(const)

      # make sure the class we want to patch exists;
      # make sure the #sanitize_sql_activerecord5 method exists and accepts exactly
      # one arguments
      unless const && mtd && mtd.arity == 1
        raise "Could not find class or method when patching "\
          "CanCan::ModelAdapters::ActiveRecord5Adapter#sanitize_sql_activerecord5. Please investigate."
      end

      # do not patch and warn if cancancan version >= 3.2
      unless cancancan_version_ok?
        puts "WARNING: It looks like cancancan has been upgraded since "\
          "CanCan::ModelAdapters::ActiveRecord5Adapter#sanitize_sql_activerecord5 in "\
          "#{__FILE__}. Please re-evaluate the patch."
        return
      end

      # actually apply the patch
      const.prepend(InstanceMethods)
    end

    private

    def find_const
      Kernel.const_get('CanCan::ModelAdapters::ActiveRecord5Adapter')
    rescue NameError
      # return nil if the constant doesn't exist
    end

    def find_method(const)
      return unless const
      const.instance_method(:sanitize_sql_activerecord5)
    rescue NameError
      # return nil if the method doesn't exist
    end

    def cancancan_version_ok?
      Gem::Version.new(CanCan::VERSION) < Gem::Version.new('3.2')
    end
  end

  module InstanceMethods
    def sanitize_sql_activerecord5(conditions)
      table = @model_class.send(:arel_table)
      table_metadata = ActiveRecord::TableMetadata.new(@model_class, table)
      predicate_builder = ActiveRecord::PredicateBuilder.new(table_metadata)

      predicate_builder.build_from_hash(conditions.stringify_keys).map { |b| visit_nodes(b) }.join(' AND ')
    end
  end
end

CancancanMonkeypatch.apply_patch
