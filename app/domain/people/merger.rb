# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module People
  class Merger

    def initialize(src_person_id, dst_person_id, actor)
      @src_person = Person.find(src_person_id)
      @dst_person = Person.find(dst_person_id)
      @actor = actor
    end

    def merge!
      Person.transaction do
        create_log_entry
        merge_associations
        # remove src person first to avoid validation errors (e.g. uniqueness)
        @src_person.destroy!
        merge_person_attrs
      end
    end

    private

    def merge_associations
      merge_roles
      merge_contactables
    end

    def merge_contactables
      merge_contactable(:additional_emails, :email)
      merge_contactable(:phone_numbers, :number)
      merge_contactable(:social_accounts, :name, match_label: true)
    end

    def merge_contactable(assoc, key, match_label: false)
      @src_person.send(assoc).each do |c|
        find_attrs = { key => c.send(key) }
        find_attrs[:label] = c.label if match_label
        existing = @dst_person.send(assoc).find_by(find_attrs)
        return if existing.present?

        dup = c.dup
        dup.contactable = @dst_person
        dup.save!
      end
    end

    def merge_roles
      @src_person.roles.each do |role|
        Role.find_or_create_by!(
          type: role.type,
          person: @dst_person,
          group: role.group
        )
      end
    end

    def merge_person_attrs
      person_attrs.each do |a|
        assign(a)
      end
      @dst_person.save!
    end

    def assign(attr)
      dst_value = @dst_person.send(attr)
      return if dst_value.present?

      src_value = @src_person.send(attr)
      @dst_person.send("#{attr}=", src_value)
    end

    def create_log_entry
      PaperTrail::Version.create!(main: @dst_person,
                                  item: @dst_person,
                                  whodunnit: @actor.id,
                                  event: :person_merge,
                                  object_changes: src_person_details)
    end

    def src_person_details
      src_person_attrs.merge(src_person_roles).to_yaml
    end

    def person_attrs
      Person::PUBLIC_ATTRS - [:id, :primary_group_id]
    end

    def src_person_attrs
      person_attrs.each_with_object({}) do |a, h|
        value = @dst_person.send(a)
        next if value.blank?

        h[a] = value
      end
    end

    def src_person_roles
      roles = @src_person.roles
      return {} if roles.empty?

      roles = roles.collect do |r|
        "#{r} (#{r.group.with_layer.join(' / ')})"
      end

      { roles: roles }
    end

  end
end
