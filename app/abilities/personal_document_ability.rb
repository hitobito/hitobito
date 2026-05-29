# frozen_string_literal: true

# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito_bienenschweiz and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/renuo/bienenschweiz-hitobito/tree/develop/hitobito_bienenschweiz

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
