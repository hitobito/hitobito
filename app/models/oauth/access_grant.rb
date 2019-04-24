module Oauth
  class AccessGrant < Doorkeeper::AccessGrant
    belongs_to :person, foreign_key: :resource_owner_id

    scope :list, -> { order(created_at: :desc) }
    scope :for,  ->(uri) { where(redirect_uri: uri) }

    def expires_at
      created_at + expires_in
    end
  end
end
