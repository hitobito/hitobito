# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PersonAddRequestsHelper

  def require_person_add_requests_button
    options = {}
    required = @group.require_person_add_requests
    options[:method] = required ? :delete : :post
    title = required ? 'deactivate_title' : 'activate_title'
    options[:title] = t("group.person_add_requests.index.#{title}")
    url = group_person_add_requests_path(@group)

    toggle_button(url, required, nil, options)
  end

  def approver_layer_roles(person)
    types = Person::AddRequest::IgnoredApprover.approver_role_types
    person.roles.select do |r|
      types.include?(r.class) && r.group.layer_group_id == @group.id
    end.collect(&:to_s).join(', ')
  end

end
