#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class Person::AddRequest::MailingList < Person::AddRequest
  belongs_to :body, class_name: "::MailingList"

  def to_s(_format = :default)
    group = body.group
    list_label = body_label
    group_label = "#{group.model_name.human} #{group}"
    self.class.human_attribute_name(:label, body: list_label, group: group_label)
  end
end
