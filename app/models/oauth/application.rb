# == Schema Information
#
# Table name: oauth_applications
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  uid          :string(255)      not null
#  secret       :string(255)      not null
#  redirect_uri :text(65535)      not null
#  scopes       :string(255)      default(""), not null
#  confidential :boolean          default(TRUE), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

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
