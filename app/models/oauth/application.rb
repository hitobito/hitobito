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

    scope :list, -> { order(:name) }

    def self.human_scope(key)
      I18n.t("doorkeeper.scopes.#{key}")
    end

    def to_s
      name
    end

    def path_params(uri)
      { client_id: uid, redirect_uri: uri, response_type: 'code', scope: scopes }
    end

    def valid_access_tokens
      access_tokens.select do |access_token|
        !access_token.expired? && access_token.revoked_at.nil?
      end.count
    end

    def valid_access_grants
      access_grants.select do |access_grant|
        !access_grant.expired? && access_grant.revoked_at.nil?
      end.count
    end
  end
end
