# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


module Oauth
  class ProfilesController < ActionController::Base

    # Make brakeman happy, even though we don't have any POST actions in this controller
    protect_from_forgery with: :exception

    before_action do
      doorkeeper_authorize! :with_roles, :email, :name
    end

    def show
      if scope.blank? || doorkeeper_token.acceptable?(scope)
        render json: basic_attrs.merge(scope_attrs || {})
      else
        render json: { error: "invalid scope: #{scope}" }, status: :forbidden
      end
    end

    private

    def scope_attrs
      return if scope.blank?

      claims = Doorkeeper::OpenidConnect.configuration.claims.to_h.values.select do |claim|
        claim.scope == scope.to_sym
      end

      claims.each_with_object({}) do |claim, data|
        data[claim.name.to_s] = claim.generator.call(person)
      end
    end

    def scope
      request.headers['X-Scope'].to_s
    end

    def person
      @person ||= Person.find(doorkeeper_token.resource_owner_id)
    end

    def basic_attrs
      { id: person.id, email: person.email }
    end
  end
end
