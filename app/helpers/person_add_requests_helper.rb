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
    url = group_person_add_requests_path(@group)

    toggle_button(url, required, nil, options)
  end

end
