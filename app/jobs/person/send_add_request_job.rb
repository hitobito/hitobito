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

    ask_person
    ask_responsibles

    # as a little extra, maintain the ignored approvers here
    clear_old_ignored_approvers
  end

  private

  def ask_person
    if person.password?
      Person::AddRequestMailer.ask_person_to_add(request).deliver_now
    end
  end

  def ask_responsibles
    responsibles = load_responsibles.to_a
    if responsibles.present?
      Person::AddRequestMailer.ask_responsibles(request, responsibles).deliver_now
    end
  end

  def load_responsibles
    Person::AddRequest::IgnoredApprover.approvers(person_layer)
  end

  def clear_old_ignored_approvers
    Person::AddRequest::IgnoredApprover.delete_old_ones
  end

  def request
    @request ||= Person::AddRequest.find(@request_id)
  end

  def person
    request.person
  end

  def person_layer
    person.primary_group.try(:layer_group) || last_layer_group
  end

  def last_layer_group
    last_role = person.last_non_restricted_role
    last_role && last_role.group.layer_group
  end

end
