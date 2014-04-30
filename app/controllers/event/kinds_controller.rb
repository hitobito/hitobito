# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::KindsController < SimpleCrudController

  self.permitted_attrs = [:label, :short_name, :minimum_age,
                          qualification_kind_ids: [],
                          precondition_ids: [],
                          prolongation_ids: []]

  self.sort_mappings = { label:      'event_kind_translations.label',
                         short_name: 'event_kind_translations.short_name' }

  before_render_form :load_assocations


  private

  def list_entries
    super.list
  end

  def load_assocations
    # possible qualification kinds. May happen if they are marked as deleted.
    @preconditions = possible_qualification_kinds | entry.preconditions
    @prolongations = (possible_qualification_kinds | entry.prolongations) - unlimited_qualifications
    @qualification_kinds = possible_qualification_kinds | entry.qualification_kinds
  end

  def possible_qualification_kinds
    @possible_qualification_kinds ||= QualificationKind.without_deleted.list
  end

  def unlimited_qualifications
    QualificationKind.where(validity: nil)
  end

  class << self
    def model_class
      Event::Kind
    end
  end

end
