# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JsonApi
  class InvoiceAbility
    include CanCan::Ability

    def initialize(user)
      @user_context = AbilityDsl::UserContext.new(user)
      can :index, Invoice, build_conditions
      can :index, InvoiceItem, {invoice: build_conditions}
    end

    private

    attr_reader :user_context

    def build_conditions
      layer_group_ids = user_context.permission_layer_ids(:finance)
      {group: {layer_group_id: layer_group_ids, archived_at: nil}}
    end
  end
end
