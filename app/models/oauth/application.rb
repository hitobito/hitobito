module Oauth
  class Application < Doorkeeper::Application
    has_many :access_grants, dependent: :delete_all, class_name: 'Oauth::AccessGrant'
    has_many :access_tokens, dependent: :delete_all, class_name: 'Oauth::AccessToken'

    def to_s
      name
    end
  end
end
