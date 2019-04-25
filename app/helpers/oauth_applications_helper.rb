module OauthApplicationsHelper

  def oauth_callback_title(application, uri)
    buttons = []
    buttons << action_button(t('doorkeeper.applications.buttons.authorize'),
                             oauth_authorization_path(path_params), :plus, class: 'btn-small')
    buttons << action_button(t('global.button.copy'),
                             oauth_authorization_url(path_params), :copy, class: 'btn-small')

    content_tag(:h3, safe_join([uri, content_tag(:span, safe_join(buttons), class: 'pull-right')]))
  end


end
