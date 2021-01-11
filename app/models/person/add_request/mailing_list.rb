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

class Person::AddRequest::MailingList < Person::AddRequest

  belongs_to :body, class_name: '::MailingList'

  def to_s(_format = :default)
    group = body.group
    list_label = body_label
    group_label = "#{group.model_name.human} #{group}"
    self.class.human_attribute_name(:label, body: list_label, group: group_label)
  end

end
