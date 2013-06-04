module AbilityDsl
  class Base

    private
    attr_reader :user_context, :subject, :permission, :action

    public

    def initialize(user_context, subject, permission, action)
      @user_context = user_context
      @subject = subject
      @permission = permission
      @action = action
    end

    class << self
      attr_reader :subject_class, :configs

      # an ability class may define mulitple subject classes,
      # but a subject class may only appear in one ability class.
      def on(subject_class, &block)
        @configs ||= {}
        @configs[subject_class] ||= []
        @configs[subject_class] << block
      end

      def subject_classes
        @configs.keys
      end

      def condition_methods
        # public methods from base and all subclasses
        ancestors.each_with_object([]) do |current, methods|
          methods.concat(current.public_instance_methods(false))
          break methods if current == AbilityDsl::Base
        end
      end
    end

    # called for any permission, action and condition except :all
    # TODO refactor to dsl
    def general_conditions
      true
    end

    def all
      true
    end

    def none
      false
    end

    private

    def permission_in_group?(group_id)
      user_groups.include?(group_id)
    end

    def permission_in_groups?(group_ids)
      contains_any?(user_groups, group_ids)
    end

    def permission_in_layer?(layer_id)
      user_layers.include?(layer_id)
    end

    def permission_in_layers?(layer_ids)
      contains_any?(user_layers, layer_ids)
    end

    def user_groups
      @user_groups ||= case permission
      when :group_full, :layer_full then user_context.groups_group_full
      when :group_read, :layer_read then user_context.groups_group_read
      else []
      end
    end

    def user_layers
      @user_layers ||= case permission
      when :layer_full then user_context.layers_full
      when :layer_read then user_context.layers_read
      else []
      end
    end

    # Are any items of the existing list present in the list of required items?
    def contains_any?(required, existing)
      (required & existing).present?
    end

    def user
      user_context.user
    end

    def subject_class
      self.class.subject_class
    end

  end
end