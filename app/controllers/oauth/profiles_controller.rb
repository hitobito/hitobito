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
        render json: email_attrs.merge(scope_attrs || {})
      else
        render json: { error: "invalid scope: #{scope}" }, status: :forbidden
      end
    end

    private

    def scope_attrs
      case scope
      when /name/
        person.attributes.slice('first_name', 'last_name', 'nickname')
      when /with_roles/
        public_attrs_with_roles
      end
    end

    def scope
      request.headers['X-Scope'].to_s
    end

    def person
      @person ||= Person.find(doorkeeper_token.resource_owner_id)
    end

    def public_attrs_with_roles
      roles = person.roles.includes(:group).collect do |role|
        {
          group_id: role.group_id,
          group_name: role.group.name,
          role_name: role.class.model_name.human,
          permissions: role.class.permissions
        }
      end
      person.attributes.slice(*Person::PUBLIC_ATTRS.collect(&:to_s)).merge(roles: roles)
    end

    def email_attrs
      { id: person.id, email: person.email }
    end
  end
end
