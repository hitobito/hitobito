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
      Person::AddRequestMailer.ask_person_to_add(request).deliver_now
    end
    Person::AddRequestMailer.ask_responsibles(request, responsibles).deliver_now
  end

  private

  def person_layer
    request.person.primary_group
  end

  def responsibles
    Person.in_layer(request.person.primary_group).
      where(roles: { type: responsible_role_types.collect(&:sti_name) })
  end

  def responsible_role_types
    Role.all_types.select do |type|
      (type.permissions & [:layer_full, :layer_and_below_full]).present?
    end
  end

  def request
    @request ||= Person::AddRequest.find(@request_id)
  end

end
