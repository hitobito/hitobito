# == Schema Information
#
# Table name: oauth_access_grants
#
#  id                :integer          not null, primary key
#  resource_owner_id :integer          not null
#  application_id    :integer          not null
#  token             :string(255)      not null
#  expires_in        :integer          not null
#  redirect_uri      :text(65535)      not null
#  created_at        :datetime         not null
#  revoked_at        :datetime
#  scopes            :string(255)
#

module Oauth
  class AccessGrant < Doorkeeper::AccessGrant
    belongs_to :person, foreign_key: :resource_owner_id

    scope :list, -> { order(created_at: :desc) }
    scope :for,  ->(uri) { where(redirect_uri: uri) }
    scope :active, -> { where(revoked_at: nil) }

    def to_s
      token
    end

    def expired?
      (created_at + expires_in) < Time.zone.now
    end

  end
end
