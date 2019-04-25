module Oauth
  class Application < Doorkeeper::Application
    has_many :access_grants, dependent: :delete_all, class_name: 'Oauth::AccessGrant'
    has_many :access_tokens, dependent: :delete_all, class_name: 'Oauth::AccessToken'

    def self.human_scope(key)
      I18n.t("doorkeeper.scopes.#{key}")
    end

    def human_scopes
      scopes.collect { |key| self.class.human_scope(key) }
    end

    def to_s
      name
    end

    def path_params(uri)
      { client_id: uid, redirect_uri: uri, response_type: 'code', scope: scopes }
    end
  end
end
