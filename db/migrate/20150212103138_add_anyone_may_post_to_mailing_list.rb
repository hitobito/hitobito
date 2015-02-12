# encoding: utf-8

#  Copyright (c) 2012-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class AddAnyoneMayPostToMailingList < ActiveRecord::Migration
  def change
    add_column :mailing_lists, :anyone_may_post, :boolean, default: false, null: false
  end
end
