# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddMailchimpSynchingFlags < ActiveRecord::Migration[6.0]
  def change
    add_column :mailing_lists, :mailchimp_sync_first_name, :boolean, default: true
    add_column :mailing_lists, :mailchimp_sync_last_name, :boolean, default: true
    add_column :mailing_lists, :mailchimp_sync_nickname, :boolean, default: true
    add_column :mailing_lists, :mailchimp_sync_gender, :boolean, default: true
  end
end
