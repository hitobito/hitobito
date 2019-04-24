module Oauth
  class AccessToken < Doorkeeper::AccessGrant
    belongs_to :person, foreign_key: :resource_owner_id

  end
end
