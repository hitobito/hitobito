#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestsController < ApplicationController
  authorize_resource

  prepend_before_action :entry

  def approve
    approver = Person::AddRequest::Approver.for(entry, current_user)
    if approver.approve
      redirect_back fallback_location: person_path(entry.person),
                    notice: t("person.add_requests.approve.success_notice", person: entry.person.full_name)
    else
      redirect_back fallback_location: person_path(entry.person),
                    alert: t("person.add_requests.approve.failure_notice",
                      person: entry.person.full_name,
                      errors: approver.error_message)
    end
  end

  def reject
    Person::AddRequest::Approver.for(entry, current_user).reject
    action = params[:cancel] ? "cancel" : "reject"
    redirect_back fallback_location: person_path(entry.person),
                  notice: t("person.add_requests.#{action}.success_notice",
                    person: entry.person.full_name)
  end

  private

  def entry
    @entry ||= Person::AddRequest.find(params[:id])
  end
end
