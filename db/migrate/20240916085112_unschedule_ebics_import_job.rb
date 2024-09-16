# frozen_string_literal: true

#  Copyright (c) 2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class UnscheduleEbicsImportJob < ActiveRecord::Migration[6.1]
  def up
    Delayed::Job.where("handler LIKE '%Payments::EbicsImportJob%'").delete_all
  end

  def down
  end
end
