# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::CourseResource < EventResource
  with_options writable: false, filterable: false, sortable: false do
    attribute :state, :string, filterable: true
    attribute :training_days, :float
    attribute :applicant_count, :integer
    attribute :participant_count, :integer
    attribute :minimum_participants, :integer
    attribute :number, :string, filterable: true
    attribute :teamer_count, :integer
  end

  belongs_to :kind, resource: Event::KindResource
  has_many :leaders, resource: Person::NameResource, writable: false,
    foreign_key: :leads_course_id

  def base_scope
    Event::Course.all.accessible_by(index_ability).includes(:groups, :translations).list
  end

  def resolve(scope)
    scope.to_a.tap do |events|
      events.each { |event| event.singleton_class.attr_accessor :leaders }
    end
  end
end
