module Role::Types
  extend ActiveSupport::Concern

  # All possible permissions
  Permissions = [:admin, :layer_full, :layer_read, :group_full, :group_read,
                 :contact_data, :approve_applications]

  # If a role contains the first permission, the second one is automatically active as well
  PermissionImplications = {:layer_full => :layer_read,
                            :group_full => :group_read}

  included do
    class_attribute :permissions, :visible_from_above, :affiliate, :restricted
    # All permission a person with this role has on the corresponding group.
    self.permissions = []
    # Whether a person with this role is visible for somebody with layer_read permission above the current layer.
    self.visible_from_above = true
    # Whether this role is an active member or an affiliate person of the corresponding group.
    self.affiliate = false
    # Whether this kind of role is specially managed or open for general modifications.
    # A restricted role should always be an affiliate as well
    self.restricted = false
  end

  module ClassMethods
    # All role types defined in the application.
    def all_types
      # do a double reverse to get roles appearing more than once at the end (uniq keeps the first..)
      @@all_types ||= Group.all_types.collect(&:role_types).flatten.reverse.uniq.reverse
    end

    # Role types that are visible from above layers
    def visible_types
      all_types.select(&:visible_from_above)
    end

    # Role types that contain all of the given permissions
    def types_with_permission(*permissions)
      all_types.select {|r| (permissions - r.permissions).blank? }
    end

    # Role types with affiliate = true
    def affiliate_types
      all_types.select(&:affiliate)
    end

    # Role types that are external.
    def external_types
      all_types.select(&:external?)
    end

    # An role external to a group, i.e. affiliate but not restricted
    def external?
      affiliate && !restricted
    end

    # Helper method to clear the cached role types.
    def reset_types!
      @@all_types = nil
    end

    def label
      model_name.human
    end

    def label_long
      I18n.translate("activerecord.models.#{model_name.i18n_key}.long",
                     default: label_with_group)
    end

    def label_with_group
      group_key = "activerecord.models.#{group.model_name.deconstantize.constantize.model_name.i18n_key}"
      [label, I18n.translate("#{group_key}.long",count: 1, default: I18n.translate("#{group_key}"))].join(' ')
    end

  end
end
