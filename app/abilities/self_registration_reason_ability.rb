# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class SelfRegistrationReasonAbility < AbilityDsl::Base

  on(SelfRegistrationReason) do
    FeatureGate.if(:self_registration_reason) do
      class_side(:index).if_admin

      permission(:admin).may(:manage).all
    end
  end

end
