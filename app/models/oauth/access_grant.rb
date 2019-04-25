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
