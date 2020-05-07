# encoding: utf-8

#  Copyright (c) 2015, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddSignatureFieldsToEvents < ActiveRecord::Migration[4.2]

  def up
    add_if_missing(:events, :signature, :boolean)
    add_if_missing(:events, :signature_confirmation, :boolean)
    add_if_missing(:events, :signature_confirmation_text, :string)
  end

  def down
    remove_if_present(:events, :signature)
    remove_if_present(:events, :signature_confirmation)
    remove_if_present(:events, :signature_confirmation_text)
  end

  private

  def add_if_missing(table, column, type, args = {})
    if !column_exists?(table, column)
      add_column(table, column, type, args)
    end
  end

  def remove_if_present(table, column)
    if column_exists?(table, column)
      remove_column(table, column)
    end
  end
end
