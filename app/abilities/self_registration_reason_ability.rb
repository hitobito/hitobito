# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class SelfRegistrationReasonAbility < AbilityDsl::Base

  on(SelfRegistrationReason) do
    class_side(:index).all

    permission(:any).may(:show, :index).all
    permission(:admin).may(:manage).all
  end

end
