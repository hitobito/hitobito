# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  class InvoiceAbility
    include CanCan::Ability

    def initialize(main_ability)
      can :index, Invoice, build_conditions(main_ability)
      can :index, InvoiceItem, { invoice: build_conditions(main_ability) }
    end

    private

    def build_conditions(main_ability)
      layer_group_ids = read_layer_ids(main_ability)
      { group: { layer_group_id: layer_group_ids, archived_at: nil } }
    end

    def read_layer_ids(main_ability)
      case main_ability
      when TokenAbility then [main_ability.token.layer.id] if main_ability.token.invoices?
      else main_ability.user_context.permission_layer_ids(:finance)
      end
    end
  end
end
