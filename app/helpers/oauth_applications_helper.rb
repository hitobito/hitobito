# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module OauthApplicationsHelper
  def oauth_spec_link(anchor)
    url = ["https://tools.ietf.org/html/rfc6749", anchor].join("#")
    link_to(url, url, target: :_blank)
  end

  def format_doorkeeper_application_scopes(application)
    human_scopes = application.scopes.collect do |key|
      format_doorkeeper_application_scope(key)
    end.collect(&:html_safe)

    simple_list(human_scopes, class: "unstyled")
  end

  def format_doorkeeper_application_scope(key)
    Oauth::Application.human_scope(key) << " " << muted("(#{key})")
  end
end
