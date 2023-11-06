# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

def gr(resource, scope: nil, params: {}, as: Role.first.person)
  raise "#{resource} is not a resource class" unless resource <= ApplicationResource

  context = OpenStruct.new(current_ability: Ability.new(as))
  Graphiti.with_context(context, params: params) do
    action_controller_params = ActionController::Parameters.new(params)
    resources = resource.all(action_controller_params, scope || resource.new.base_scope)
    JSON.parse(resources.to_jsonapi).deep_symbolize_keys
  end
end
