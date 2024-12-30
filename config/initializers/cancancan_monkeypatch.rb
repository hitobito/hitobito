# In 3.2.0, cancan introduced better support for STI models:
# https://github.com/CanCanCommunity/cancancan/pull/649
#
# Unfortunately, this breaks our class_side ability DSL on STI models, as something like
#   on(Event) { can(:list_available).if_any_role } and
#   on(Event::Course) { can(:list_available).everybody }
# does not work anymore.
#
# With these changes, the class_side Event::Course rules also take effect
# when querying can?(:something, Event).

# The bug is described in the follwing issue, but its not active atm
# https://github.com/CanCanCommunity/cancancan/issues/771
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
        raise "Could not find class or method when patching " \
          "CanCan::Ability#alternative_subjects. Please investigate."
      end

      # do not patch and warn if cancancan version >= 3.2
      unless cancancan_version_ok?
        puts "WARNING: It looks like cancancan has been upgraded since " \
          "CanCan::Ability#alternative_subjects in " \
          "#{__FILE__}. Please re-evaluate the patch."
        return
      end

      # actually apply the patch
      const.prepend(InstanceMethods)
    end

    private

    def find_const
      Kernel.const_get("CanCan::Ability")
    rescue NameError
      # return nil if the constant doesn't exist
    end

    def find_method(const)
      return unless const
      const.instance_method(:alternative_subjects)
    rescue NameError
      # return nil if the method doesn't exist
    end

    def cancancan_version_ok?
      Gem::Version.new(CanCan::VERSION) < Gem::Version.new("3.7")
    end
  end

  module InstanceMethods
    def alternative_subjects(subject)
      subject = subject.class unless subject.is_a?(Module)
      [:all, *subject.ancestors, subject.class.to_s]
    end
  end
end

CancancanMonkeypatch.apply_patch
