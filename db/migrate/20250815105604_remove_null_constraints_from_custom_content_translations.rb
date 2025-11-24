#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Removes the NOT NULL constraint from the label column in custom_content_translations
# to allow partial translations across languages.
#
# With the introduction of globalized input fields, users can now fill in translations
# for custom content in multiple languages. However, they should not be required to
# provide translations in ALL languages - it's acceptable to have some languages filled
# and others empty.
#
# The label column had a NOT NULL constraint, which prevented saving custom content
# when any language translation was left empty. This would cause validation errors
# like "Label can't be blank" even when the label was filled in the current locale.
# By removing the NOT NULL constraint, we allow the translations table to have NULL
# values for label in languages that haven't been filled in yet. The application-level
# validation still ensures that at least the current locale is present (via the
# presence validator on CustomContent#label).
class RemoveNullConstraintsFromCustomContentTranslations < ActiveRecord::Migration[7.1]
  def change
    change_column_null :custom_content_translations, :label, true
  end
end
