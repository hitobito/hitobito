# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestDecorator < ApplicationDecorator
  decorates "person/add_request"
  decorates_association :person

  def body_path
    case object
    when Person::AddRequest::Group
      h.group_path(body_id)
    when Person::AddRequest::Event
      h.group_event_path(body.groups.first, body_id)
    when Person::AddRequest::MailingList
      h.group_mailing_list_path(body.group_id, body_id)
    else
      raise NotImplementedError
    end
  end

  def body_details
    case object
    when Person::AddRequest::Group
      body.class.find_role_type!(role_type).model_name.human
    when Person::AddRequest::Event
      body.groups.join(", ")
    when Person::AddRequest::MailingList
      body.group.to_s
    else
      raise NotImplementedError
    end
  end

end
