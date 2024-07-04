#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Approver
  class Base
    attr_reader :request, :user

    def initialize(request, user)
      @request = request
      @user = user
    end

    def approve
      Person.transaction do
        success = entity.save
        if success
          send_approval if email.present?
          request.destroy
        end
        success
      end
    end

    def reject
      Person.transaction do
        if email.present? && user.id != request.requester_id
          send_rejection
        end
        request.destroy
      end
    end

    def entity
      @entity ||= build_entity
    end

    def error_message
      entity.errors.full_messages.join(", ")
    end

    private

    def send_approval
      Person::AddRequestMailer
        .approved(request.person, request.body, request.requester, user)
        .deliver_later
    end

    def send_rejection
      Person::AddRequestMailer
        .rejected(request.person, request.body, request.requester, user)
        .deliver_later
    end

    def build_entity
      raise(NotImplementedError)
    end

    def email
      request.person.email
    end
  end
end
