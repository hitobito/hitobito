module OauthApplicationsHelper

  def oauth_spec_link(anchor)
    url = ['https://tools.ietf.org/html/rfc6749', anchor].join('#')
    link_to(url, url, target: :_blank)
  end

end
