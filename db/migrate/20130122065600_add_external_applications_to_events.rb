# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddExternalApplicationsToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :external_applications, :boolean, :default => false
  end
end
