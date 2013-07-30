# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'devise/strategies/token_authenticatable'

module Devise
  module Strategies
    # Strategy for signing in a user one single time, based on a authenticatable token.
    # All you need to do is to pass the params in the URL:
    #
    #   http://myapp.example.com/?ontime_token=SECRET
    #
    class OneTimeTokenAuthenticatable < TokenAuthenticatable

      def authenticate!
        token = authentication_hash[authentication_keys.first]
        resource = mapping.to.find_for_authentication(reset_password_token: token)
        return fail(:invalid_token) unless resource

        success = validate(resource) do
          resource.reset_password_period_valid?
        end
        
        if success
          resource.clear_reset_password_token!
          success!(resource)
        end
      end

    private

      # Overwrite authentication keys to use token_authentication_key.
      def authentication_keys
        @authentication_keys ||= [:onetime_token]
      end
    end
  end
end

