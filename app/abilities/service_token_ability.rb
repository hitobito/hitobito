# frozen_string_literal: true

#  Copyright (c) 2018-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ServiceTokenAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Group

  on(ServiceToken) do
    permission(:layer_and_below_full).may(:manage).service_token_in_same_layer
    permission(:layer_full).may(:manage).service_token_in_same_layer
  end

  def service_token_in_same_layer
    in_same_layer
  end

  private

  def group
    subject.layer
  end

end
