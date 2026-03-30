#  Copyright (c) 2021-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# A doorkeeper token ability is like a normal ability, except it is based on a
# personal OAuth access token and uses the person who logged in via OAuth for
# calculating the permissions.
# Also, an OAuth application has allowed scopes (e.g. :people, :groups, ...)
# which limit the permissions that are actually granted.
# If the access token has the scope :api, this is treated the same as if all
# API scopes (like :people, :groups, ...) were set.
class DoorkeeperTokenAbility < Ability
  include ApiScopeAbility

  attr_reader :token

  def initialize(doorkeeper_token)
    return if doorkeeper_token.nil?
    @token = doorkeeper_token
    super(Person.find(doorkeeper_token.resource_owner_id))
  end

  private

  def acceptable?(scope)
    token.acceptable?(scope) || token.acceptable?(:api)
  end

  def write_permission?
    # Allow to inherit abilities with write permission for OAuth access tokens.
    # There is currently no way to disable the writing capabilities of an OAuth
    # access token like we have with service tokens.
    # This does not mean that the token is allowed to write anywhere, it just means
    # it's allowed to write where the user is allowed to write.
    true
  end
end
