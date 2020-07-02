# == Schema Information
#
# Table name: oauth_access_tokens
#
#  id                     :integer          not null, primary key
#  resource_owner_id      :integer
#  application_id         :integer
#  token                  :string(255)      not null
#  refresh_token          :string(255)
#  expires_in             :integer
#  revoked_at             :datetime
#  created_at             :datetime         not null
#  scopes                 :string(255)
#  previous_refresh_token :string(255)      default(""), not null
#

module Oauth
  class AccessToken < Doorkeeper::AccessToken
    belongs_to :person, foreign_key: :resource_owner_id

    scope :list, -> { order(created_at: :desc) }
    scope :active, -> { where(revoked_at: nil) }

    def to_s
      token
    end

    def expired?
      (created_at + expires_in) < Time.zone.now
    end
  end
end
