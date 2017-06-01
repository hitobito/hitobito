# encoding: utf-8

#  Copyright (c) 2015, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddEventApplicationWaitingListComment < ActiveRecord::Migration
  def change
    add_column :event_applications, :waiting_list_comment, :text
  end
end
