#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_question_templates
#
#  id          :bigint           not null, primary key
#  default     :boolean          default(FALSE), not null
#  event_type  :string
#  inherit     :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  group_id    :bigint           not null
#  question_id :bigint           not null
#
# Indexes
#
#  index_event_question_templates_on_group_id     (group_id)
#  index_event_question_templates_on_question_id  (question_id)
#
class Event::QuestionTemplate < ActiveRecord::Base
  belongs_to :question, dependent: :destroy
  belongs_to :group

  scope :in_hierarchy, ->(groups) {
    layer_ids = groups.map(&:layer_group_id).uniq
    hierarchy_ids = groups.flat_map { |g| g.hierarchy.pluck(:layer_group_id) }.uniq

    where("group_id IN (?) OR (group_id IN (?) AND inherit IS TRUE)", layer_ids, hierarchy_ids)
  }

  def self.applicable_to(groups, event_type: nil, admin: false)
    return none if groups.blank?

    joins(:question)
      .where(default: true, event_type: [event_type, nil])
      .in_hierarchy(groups)
      .merge(Event::Question.where(admin: admin).list)
      .select(attribute_names)
  end

  def derive_question
    attrs = question.attributes.excluding("id", "created_at", "updated_at")
    Event::Question.build(attrs).tap do |derived_question|
      derived_question.derived = true
      derived_question.template_id = id

      # copy translations from template question
      [:question, :choices].each do |attribute|
        template_translations = question.send(:"#{attribute}_translations")
        derived_question.send(:"#{attribute}_translations=", question.globalize_locales
                                                                     .map { [_1.to_s, nil] }
                                                                     .to_h
                                                                     .merge(template_translations))
      end
    end
  end
end
