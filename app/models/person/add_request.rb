# frozen_string_literal: true

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: person_add_requests
#
#  id           :integer          not null, primary key
#  role_type    :string(255)
#  type         :string(255)      not null
#  created_at   :datetime         not null
#  body_id      :integer          not null
#  person_id    :integer          not null
#  requester_id :integer          not null
#
# Indexes
#
#  index_person_add_requests_on_person_id         (person_id)
#  index_person_add_requests_on_type_and_body_id  (type,body_id)
#

class Person::AddRequest < ActiveRecord::Base
  has_paper_trail meta: {main_id: ->(r) { r.person_id },
                         main_type: Person.sti_name}

  belongs_to :person
  belongs_to :requester, class_name: "Person"

  validates_by_schema
  validates :person_id, uniqueness: {scope: [:type, :body_id]}

  scope :list, (lambda do
    includes(:person).references(:person).merge(Person.order_by_name).order(:created_at)
  end)

  class << self
    def for_layer(layer_group)
      joins(:person).
        joins("LEFT JOIN #{::Group.quoted_table_name} AS primary_groups " \
              "ON primary_groups.id = people.primary_group_id").
        where("primary_groups.layer_group_id = ? OR people.id IN (?)",
          layer_group.id,
          ::Group::DeletedPeople.deleted_for(layer_group).select(:id))
    end
  end

  # This statement is required because these classes would not be loaded correctly otherwise.
  # The price we pay for using classes as namespace.
  require_dependency "person/add_request/group"
  require_dependency "person/add_request/event"
  require_dependency "person/add_request/mailing_list"

  def to_s(_format = :default)
    body_label
  end

  def body_label
    "#{body.class.model_name.human} #{body}"
  end

  def person_layer
    person.primary_group.try(:layer_group) || last_layer_group
  end

  def requester_full_roles
    requester.roles.includes(:group).select do |r|
      (r.class.permissions &
        [:layer_and_below_full, :layer_full, :group_and_below_full, :group_full]).present?
    end
  end

  private

  def last_layer_group
    last_role = person.last_non_restricted_role
    return unless last_role

    last_role.group.layer_group
  end
end
