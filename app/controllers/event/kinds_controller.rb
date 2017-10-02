# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::KindsController < SimpleCrudController

  self.permitted_attrs = [:label, :short_name, :minimum_age,
                          :general_information, :application_conditions,
                          precondition_qualification_kinds: [{ qualification_kind_ids: [] }],
                          qualification_kinds: {
                            participant: {
                              qualification: { qualification_kind_ids: [] },
                              prolongation: { qualification_kind_ids: [] }
                            },
                            leader: {
                              qualification: { qualification_kind_ids: [] },
                              prolongation: { qualification_kind_ids: [] }
                            }
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
    precondition_attrs = attrs.delete(:precondition_qualification_kinds) || {}

    existing_kinds = entry.event_kind_qualification_kinds.to_a

    kinds_attrs = flatten_nested_qualification_kinds(kinds_attrs, existing_kinds)
    kinds_attrs += flatten_precondition_qualification_kinds(precondition_attrs, existing_kinds)
    mark_qualifikation_kinds_for_removal!(kinds_attrs, existing_kinds)

    attrs[:event_kind_qualification_kinds_attributes] = kinds_attrs
    attrs.permit!
    attrs
  end

  def flatten_nested_qualification_kinds(kinds_attrs, existing_kinds)
    kinds_attrs.flat_map do |role, categories|
      categories.flat_map do |category, ids|
        ids.fetch(:qualification_kind_ids, []).collect do |id|
          { id: find_qualification_kind_assoc_id(existing_kinds, id, role, category),
            role: role,
            category: category,
            qualification_kind_id: id }
        end
      end
    end
  end

  def flatten_precondition_qualification_kinds(grouped_ids, existing_kinds)
    grouped_ids.each_with_index.flat_map do |(_, ids), index|
      ids.fetch(:qualification_kind_ids, []).map do |id|
        { id: find_qualification_kind_assoc_id(existing_kinds, id,
                                               'participant', 'precondition', index + 1),
          role: 'participant',
          category: 'precondition',
          qualification_kind_id: id,
          grouping: index + 1 }
      end
    end
  end

  def find_qualification_kind_assoc_id(existing_kinds, qualification_kind_id, role,
                                       category, grouping = nil)
    kind = existing_kinds.find do |k|
      k.role == role &&
      k.category == category &&
      k.qualification_kind_id == qualification_kind_id &&
      k.grouping == grouping
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
