# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: person_add_requests
#
#  id           :integer          not null, primary key
#  person_id    :integer          not null
#  requester_id :integer          not null
#  type         :string           not null
#  body_id      :integer          not null
#  role_type    :string
#  created_at   :datetime         not null
#

class Person::AddRequest < ActiveRecord::Base

  has_paper_trail meta: { main_id: ->(r) { r.person_id },
                          main_type: Person.sti_name }

  belongs_to :person
  belongs_to :requester, class_name: 'Person'

  validates_by_schema
  validates :person_id, uniqueness: { scope: [:type, :body_id] }

  scope :list, -> { includes(:person).references(:person).merge(Person.order_by_name) }

  class << self
    def for_layer(layer_group)
      joins(person: :primary_group).
        where(groups: { layer_group_id: layer_group.id })
    end
  end

  # This statement is required because these classes would not be loaded correctly otherwise.
  # The price we pay for using classes as namespace.
  require_dependency 'person/add_request/group'
  require_dependency 'person/add_request/event'
  require_dependency 'person/add_request/mailing_list'


  def to_s(_format = :default)
    body_label
  end

  def body_label
    "#{body.class.model_name.human} #{body}"
  end

  def person_layer
    person.primary_group.try(:layer_group)
  end

  def requester_full_roles
    requester.roles.includes(:group).select do |r|
      (r.class.permissions &
        [:layer_and_below_full, :layer_full, :group_and_below_full, :group_full]).present?
    end
  end

end
