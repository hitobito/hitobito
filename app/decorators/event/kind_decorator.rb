# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::KindDecorator < ApplicationDecorator
  decorates 'event/kind'

  def issued_qualifications_info_for_leaders(quali_date)
    qualis = qualification_kinds('qualification', 'leader').list.to_a
    prolongs = qualification_kinds('prolongation', 'leader').list.to_a
    variables = { until: h.f(quali_date),
                  model: quali_model_name(qualis),
                  issued: qualis.join(', '),
                  prolonged: prolongs.join(', '),
                  count: prolongs.size }

    translate_issued_qualifications_info(qualis, prolongs, variables)
  end

  def issued_qualifications_info_for_participants(quali_date)
    qualis = qualification_kinds('qualification', 'participant').list.to_a
    prolongs = qualification_kinds('prolongation', 'participant').list.to_a
    variables = { until: h.f(quali_date),
                  model: quali_model_name(qualis),
                  issued: qualis.join(', '),
                  prolonged: prolongs.join(', '),
                  count: prolongs.size }

    translate_issued_qualifications_info(qualis, prolongs, variables)
  end

  private

  def translate_issued_qualifications_info(qualis, prolongs, variables)
    variables = variables.merge(scope: :event_decorator)
    if qualis.present? && prolongs.present?
      I18n.t(:issue_and_prolong, **variables)
    elsif qualis.present?
      I18n.t(:issue_only, **variables)
    elsif prolongs.present?
      I18n.t(:prolong_only, **variables)
    else
      ''
    end
  end

  def quali_model_name(list)
    Qualification.model_name.human(count: list.size)
  end
end
