#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ServiceTokenDecorator < ApplicationDecorator
  decorates :service_token

  def scopes
    safe_join(ServiceToken.possible_scopes.map do |scope|
      ServiceToken.human_attribute_name(scope) if public_send(scope)
    end.compact, h.tag(:br))
  end
end
