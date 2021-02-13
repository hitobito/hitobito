# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PersonAddRequestsHelper

  def require_person_add_requests_button
    required = @group.require_person_add_requests
    action = required ? "deactivate" : "activate"
    label = t("group.person_add_requests.actions_index.#{action}")
    url = group_person_add_requests_path(@group)
    options = {}
    options[:method] = required ? :delete : :post
    options[:title] = t("group.person_add_requests.actions_index.#{action}_title")
    add_css_class(options, "active btn-success") if required
    button(label, url, nil, options)
  end

  def approver_layer_roles(person)
    types = Person::AddRequest::IgnoredApprover.approver_role_types
    person.roles.select do |r|
      types.include?(r.class) && r.group.layer_group_id == @group.id
    end.collect(&:to_s).join(", ")
  end

end
