# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::KindsController < SimpleCrudController

  self.permitted_attrs = [:label, :short_name, :minimum_age,
                          qualification_kinds: {
                            participant: {
                              precondition: { qualification_kind_ids: [] },
                              qualification: { qualification_kind_ids: [] },
                              prolongation: { qualification_kind_ids: [] } },
                            leader: {
                              precondition: { qualification_kind_ids: [] },
                              qualification: { qualification_kind_ids: [] },
                              prolongation: { qualification_kind_ids: [] } }
                          }]

  self.sort_mappings = { label:      'event_kind_translations.label',
                         short_name: 'event_kind_translations.short_name' }

  before_render_form :load_assocations


  private

  def list_entries
    super.list
  end

  def load_assocations
    @preconditions = possible_qualification_kinds
    @prolongations = possible_qualification_kinds - unlimited_qualifications
    @qualification_kinds = possible_qualification_kinds
  end

  def possible_qualification_kinds
    @possible_qualification_kinds ||= QualificationKind.without_deleted.list
  end

  def unlimited_qualifications
    QualificationKind.without_deleted.where(validity: nil)
  end

  def permitted_params
    attrs = super
    kinds_attrs = attrs.delete(:qualification_kinds) || {}
    existing_kinds = entry.event_kind_qualification_kinds.to_a

    kinds_attrs = flatten_nested_qualification_kinds(kinds_attrs, existing_kinds)
    mark_qualifikation_kinds_for_removal!(kinds_attrs, existing_kinds)

    attrs[:event_kind_qualification_kinds_attributes] = kinds_attrs
    attrs
  end

  def flatten_nested_qualification_kinds(kinds_attrs, existing_kinds)
    kinds_attrs.flat_map do |role, categories|
      categories.flat_map do |category, ids|
        ids.fetch(:qualification_kind_ids, []).collect do |id|
          { id: qualification_kind_assoc_id(id, role, category, existing_kinds),
            role: role,
            category: category,
            qualification_kind_id: id }

        end
      end
    end
  end

  def qualification_kind_assoc_id(qualification_kind_id, role, category, existing_kinds)
    kind = existing_kinds.find do |k|
      k.role == role && k.category == category &&
        k.qualification_kind_id == qualification_kind_id
    end
    kind.try(:id)
  end

  def mark_qualifikation_kinds_for_removal!(kinds_attrs, existing_kinds)
    existing_kinds.each do |kind|
      if kinds_attrs.none? { |a| a[:id] == kind.id }
        kinds_attrs << { id: kind.id, _destroy: true }
      end
    end
  end

  class << self
    def model_class
      Event::Kind
    end
  end

end
