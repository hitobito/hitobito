# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class OidcClaimSetup
  NAME_ATTRS = %w(first_name last_name nickname) +
               %w(address address_care_of street housenumber postbox zip_code town country)
  NAME_ATTRS.freeze

  def run
    add_claim(:email, scope: [:email], responses: [:user_info, :id_token])
    add_name_scope_claims
    add_role_scope_claims
    add_nextcloud_scope_claims
  end

  private

  def add_name_scope_claims
    NAME_ATTRS.each { |attr| add_claim(attr, scope: :name) }
  end

  def add_role_scope_claims
    (Person::PUBLIC_ATTRS - [:id] + [:address]).each do |attr|
      add_claim(attr, scope: :with_roles)
    end
    add_claim(:roles, scope: :with_roles) { |owner| owner.decorate.roles_for_oauth }
  end

  def add_nextcloud_scope_claims
    FeatureGate.if('groups.nextcloud') do
      responses = [:user_info, :id_token]
      add_claim(:name, scope: :nextcloud, responses: responses) { |owner| owner.to_s }

      add_claim(:groups, scope: :nextcloud, responses: responses) do |owner|
        owner.roles.map(&:nextcloud_group).uniq.compact.map(&:to_h)
      end
    end
  end

  def add_claim(name, scope:, responses: [:user_info])
    Array(scope).each do |scope|
      claim = Doorkeeper::OpenidConnect::Claims::NormalClaim.new(
        name: name,
        scope: scope,
        response: responses,
        generator: Proc.new { |owner| block_given? ? yield(owner) : resolve(name, owner) }
      )
      Doorkeeper::OpenidConnect.configuration.claims[build_key(name.to_sym, scope)] = claim
    end
  end

  def build_key(name, scope)
    @keys ||=[]
    key = @keys.exclude?(name) ? name : [scope, name].join('_')
    key.tap { @keys << key }
  end

  def resolve(name, owner)
    respond_to?(name, private: true) ? send(name, owner) : owner.send(name)
  end
end
