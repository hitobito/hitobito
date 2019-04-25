module Oauth
  class AccessToken < Doorkeeper::AccessToken
    belongs_to :person, foreign_key: :resource_owner_id

    scope :list, -> { order(created_at: :desc) }

    def to_s
      token
    end
  end
end
