# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module GlobalizedHelpers
  def with_globalized_models(*models)
    stub_languages
    models.each do |model|
      model.globalize_accessors
      model.copy_validators_to_globalized_accessors
    end
  end

  def stub_languages(languages = {de: "Deutsch", en: "English", fr: "Français"})
    allow(Settings.application).to receive(:languages).and_return(languages)
  end
end
