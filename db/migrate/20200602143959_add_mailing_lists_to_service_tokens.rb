# encoding: utf-8

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddMailingListsToServiceTokens < ActiveRecord::Migration[6.0]
  def change
    add_column(:service_tokens, :mailing_lists, :boolean, default: false, null: false)
  end
end
