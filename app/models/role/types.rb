# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Role::Types
  extend ActiveSupport::Concern

  # rubocop:disable ConstantName

  # All possible permissions
  Permissions = [:admin, :layer_full, :layer_read, :group_full, :group_read,
                 :contact_data, :public, :approve_applications]

  # If a role contains the first permission, the second one is automatically active as well
  PermissionImplications = { layer_full: :layer_read,
                             group_full: :group_read }

  Kinds = [:member, :passive, :external]

  # rubocop:enable ConstantName

  included do
    class_attribute :permissions, :visible_from_above, :kind

    # All permission a person with this role has on the corresponding group.
    self.permissions = []

    # Whether a person with this role is visible for somebody
    # with layer_read permission above the current layer.
    self.visible_from_above = true

    # The kind of a role mainly determines in which pill it will be displayed.
    #
    # A value of nil means a that the role does not actually belong to the group
    # like members or passives, but is rather an external controller/supervisor/...
    # that needs access to the group's information. So they do not appear in the
    # people lists of the group, but rather in the group attributes.
    self.kind = :member
  end

  module ClassMethods

    # All role types defined in the application.
    def all_types
      # do a double reverse to get roles appearing more than once at the end
      # (uniq keeps the first..)
      @@all_types ||= Group.all_types.collect(&:role_types).flatten.reverse.uniq.reverse
    end

    # Role types that are visible from above layers
    def visible_types
      all_types.select(&:visible_from_above)
    end

    # Role types that contain all of the given permissions
    def types_with_permission(*permissions)
      all_types.select { |r| (permissions - r.permissions).blank? }
    end

    # An role that is a main member of a group.
    def member?
      kind == :member
    end

    # Whether this kind of role is specially managed or open for general modifications.
    def restricted?
      kind.nil?
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
      group_type = model_name.to_s.deconstantize.constantize
      group_key = "activerecord.models.#{group_type.model_name.i18n_key}"
      [label,
       I18n.translate("#{group_key}.long",
                      count: 1,
                      default: I18n.translate("#{group_key}"))
      ].join(' ')
    end

    def description
      I18n.translate("activerecord.models.#{model_name.i18n_key}.description",
                     default: '')
    end
  end

  def restricted?
    self.class.restricted?
  end
end
