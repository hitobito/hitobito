# encoding: utf-8

#  Copyright (c) 2014, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddAuthenticationTokenToPeople < ActiveRecord::Migration
  def change
    add_column :people, :authentication_token, :string
    add_index :people, :authentication_token
  end
end
