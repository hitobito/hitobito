module Oauth
  class ProfilesController < ActionController::Base
    before_action :doorkeeper_authorize!

    def show
      render json: email_attrs.merge(scope_attrs || {})
    end

    private

    def scope_attrs
      case request.headers['X-Scope'].to_s
      when /name/ then
        person.attributes.slice(*%w(first_name last_name nickname))
      when /with_roles/ then
        public_attrs_with_roles
      when /api_access/
        person.attributes.slice('authentication_token').merge(public_attrs_with_roles)
      end
    end

    def person
      @person ||= Person.find(doorkeeper_token.resource_owner_id)
    end

    def public_attrs_with_roles
      roles = person.roles.includes(:group).collect do |role|
        {
          group_id: role.group_id,
          group_name: role.group.name,
          role_name: role.class.model_name.human
        }
      end
      person.attributes.slice(*Person::PUBLIC_ATTRS.collect(&:to_s)).merge(roles: roles)
    end

    def email_attrs
      { id: person.id, email: person.email }
    end
  end
end
