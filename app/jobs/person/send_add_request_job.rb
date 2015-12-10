# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::SendAddRequestJob < BaseJob

  self.parameters = [:request_id, :locale]

  def initialize(request)
    super()
    @request_id = request.id
  end

  def perform
    set_locale

    if person.password?
      Person::AddRequestMailer.ask_person_to_add(request,
                                                 request_body_label,
                                                 requester_name,
                                                 requester_group_roles).
                                                 deliver_now
    end

    responsibles = load_responsibles.to_a
    if responsibles.present?
      Person::AddRequestMailer.ask_responsibles(request, responsibles).deliver_now
    end
  end

  private

  def load_responsibles
    Person.in_layer(person.primary_group).
      where(roles: { type: responsible_role_types.collect(&:sti_name) }).
      uniq
  end

  def responsible_role_types
    Role.all_types.select do |type|
      (type.permissions & [:layer_full, :layer_and_below_full]).present?
    end
  end

  def request
    @request ||= Person::AddRequest.find(@request_id)
  end

  def person
    request.person
  end

  def requester
    request.requester
  end

  def requester_group_roles
    roles = requester.roles.includes(:group).where(type: responsible_role_types)
    roles.collect { |r| r.to_s(:long) }.join(', ')
  end

  def requester_name
    requester.full_name
  end

  def request_body_label
    type = request.body.model_name.human
    label = request.body.to_s
    "#{type}: #{label}"
  end

end
