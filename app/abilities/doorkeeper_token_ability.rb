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
  attr_reader :token

  def initialize(doorkeeper_token)
    return if doorkeeper_token.nil?
    @token = doorkeeper_token
    super(Person.find(doorkeeper_token.resource_owner_id))
  end

  private

  def define_user_abilities(current_store, current_user_context, include_manageds = true)
    # Only consider permissions which match the service token scope settings
    limited_store = current_store.filter_configs do |_, subject_class, _, _|
      model_acceptable?(subject_class)
    end

    super(limited_store, current_user_context, include_manageds)
  end

  def model_acceptable?(model)
    case model_base_class(model)
    when "Role"
      acceptable?(:groups) && acceptable?(:people)
    when "Event::Kind", "Event::KindCategory"
      acceptable?(:events)
    when "InvoiceItem"
      acceptable?(:invoices)
    else
      scope = model_base_class(model).gsub("::", "").pluralize.underscore
      ServiceToken.possible_scopes.include?(scope) && acceptable?(scope)
    end
  end

  def model_base_class(model) = model.respond_to?(:base_class) ? model.base_class.name : model.name

  def acceptable?(scope)
    token.acceptable?(scope) || token.acceptable?(:api)
  end
end
