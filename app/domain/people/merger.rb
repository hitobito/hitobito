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
        @source.reload.destroy!
        merge_person_attrs
      end
    end

    private

    def merge_associations
      merge_roles
      merge_contactables(:additional_emails, :email)
      merge_contactables(:phone_numbers, :number)
      merge_contactables(:social_accounts, :name, match_label: true)
      merge_association(:invoices, :recipient)
      merge_association(:notes, :subject)
      merge_association(:authored_notes, :author)
      merge_association(:event_responsibilities, :contact)
      merge_association(:group_responsibilities, :contact)
      merge_association(:family_members, :person, unique_attr: :other_id)
      merge_association(:subscriptions, :subscriber, unique_attr: :mailing_list_id)
      merge_association(:event_invitations, :person, unique_attr: :event_id)
      merge_association(:event_participations, :person, unique_attr: :event_id)
      merge_association(:add_requests, :person, unique_attr: :body_id)
      merge_association(:taggings, :taggable, unique_attr: :tag_id)
      merge_qualifications
    end

    def merge_contactables(assoc, key, match_label: false)
      @source.send(assoc).each do |c|
        find_attrs = {key => c.send(key)}
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
      @source.roles.with_inactive.each do |src_role|
        dst_role = Role.find_or_initialize_by(
          role_attrs(src_role).merge(person: @target)
        )

        next unless dst_role.new_record?

        dst_role.save!
      end
    end

    def merge_association(assoc, key, unique_attr: nil)
      @source.send(assoc).each do |a|
        next if unique_attr && @target.send(assoc).pluck(unique_attr).include?(a.send(unique_attr))

        a.update!(key => @target)
      end
    end

    def merge_qualifications
      @source.qualifications.each do |qualification|
        next if @target.qualifications
          .where("start_at = :start_at OR finish_at = :finish_at", start_at: qualification.start_at, finish_at: qualification.finish_at)
          .pluck(:qualification_kind_id).include?(qualification.qualification_kind_id)

        qualification.update!(person: @target)
      end
    end

    def merge_person_attrs
      Person::MERGABLE_ATTRS.each do |a|
        assign(a)
      end
      attach_picture
      @target.save!
    end

    def assign(attr)
      dst_value = @target.send(attr)
      return if dst_value.present?

      src_value = @source.send(attr)
      @target.send(:"#{attr}=", src_value)
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

    def source_attrs
      Person::MERGABLE_ATTRS.each_with_object({}) do |a, h|
        value = @source.send(a)
        next if value.blank?

        h[a] = value
      end
    end

    def source_roles
      roles = @source.roles
      return {} if roles.empty?

      roles = roles.collect do |r|
        "#{r} (#{r.group.with_layer.join(" / ")})"
      end

      {roles: roles}
    end

    def role_attrs(src_role)
      role_attr_keys(src_role).index_with do |key|
        src_role.send(key)
      end
    end

    def role_attr_keys(src_role)
      attributes = src_role.used_attributes +
        [:type, :group, :start_on, :end_on] -
        src_role.merge_excluded_attributes
      attributes.uniq
    end
  end
end
