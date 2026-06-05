# frozen_string_literal: true

# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class PersonalDocumentAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Person

  on(PersonalDocument) do
    permission(:any).may(:read).herself
    permission(:admin).may(:manage).all
  end

  on(PersonalDocumentLabel) do
    permission(:admin).may(:manage).all
  end
end
