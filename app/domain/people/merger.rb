# frozen_string_literal: true

#  Copyright (c) 2012-2022, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module People
  class Merger

    def initialize(source, target, actor)
      @source = source
      @target = target
      @actor = actor
    end

    def merge!
      Person.transaction do
        create_log_entry
        merge_associations
        # remove src person first to avoid validation errors (e.g. uniqueness)
        @source.destroy!
        merge_person_attrs
      end
    end

    private

    def merge_associations
      merge_roles
      merge_contactables(:additional_emails, :email)
      merge_contactables(:phone_numbers, :number)
      merge_contactables(:social_accounts, :name, match_label: true)
    end

    def merge_contactables(assoc, key, match_label: false)
      @source.send(assoc).each do |c|
        find_attrs = { key => c.send(key) }
        find_attrs[:label] = c.label if match_label
        existing = @target.send(assoc).find_by(find_attrs)
        # do not merge invalid contactables
        next if existing.present? || !c.valid?

        dup = c.dup
        dup.contactable = @target
        dup.save!
      end
    end

    def merge_roles
      @source.roles.with_deleted.each do |src_role|
        dst_role = Role.find_or_initialize_by(
          role_attrs(src_role).merge(person: @target)
        )

        next unless dst_role.new_record?

        dst_role.deleted_at = src_role.deleted_at
        dst_role.save!
      end
    end

    def merge_person_attrs
      person_attrs.each do |a|
        assign(a)
      end
      attach_picture
      @target.save!
    end

    def assign(attr)
      dst_value = @target.send(attr)
      return if dst_value.present?

      src_value = @source.send(attr)
      @target.send("#{attr}=", src_value)
    end

    def attach_picture
      return if @target.picture.attached?
      return unless @source.picture.attached?

      @target.picture.attach(@source.picture)
    end

    def create_log_entry
      PaperTrail::Version.create!(main: @target,
                                  item: @target,
                                  whodunnit: @actor.id,
                                  event: :person_merge,
                                  object_changes: source_details)
    end

    def source_details
      source_attrs.merge(source_roles).to_yaml
    end

    def person_attrs
      Person::PUBLIC_ATTRS - [:id, :primary_group_id, :picture]
    end

    def source_attrs
      person_attrs.each_with_object({}) do |a, h|
        value = @target.send(a)
        next if value.blank?

        h[a] = value
      end
    end

    def source_roles
      roles = @source.roles
      return {} if roles.empty?

      roles = roles.collect do |r|
        "#{r} (#{r.group.with_layer.join(' / ')})"
      end

      { roles: roles }
    end

    def role_attrs(src_role)
      role_attr_keys(src_role).index_with do |key|
        src_role.send(key)
      end
    end

    def role_attr_keys(src_role)
      attributes = src_role.used_attributes +
        [:type, :group, :created_at] -
        src_role.merge_excluded_attributes
      attributes.uniq
    end
  end
end
