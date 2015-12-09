module PersonAddRequestsHelper

  def require_person_add_requests_button
    options = {}
    required = @group.require_person_add_requests
    options[:method] = required ? :delete : :post
    url = group_person_add_requests_path(@group)

    toggle_button(url, required, nil, options)
  end

end
