# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module GeneratedAttributeWithoutFk
  # revert default to generate with `foreign_key: false`
  # see doc/architecture/adr/008_foreign_keys.md
  def options_for_migration
    super.tap do |options|
      options.merge!(foreign_key: false) if reference?
    end
  end
end

require 'rails/generators/generated_attribute'
Rails::Generators::GeneratedAttribute.prepend(GeneratedAttributeWithoutFk)
