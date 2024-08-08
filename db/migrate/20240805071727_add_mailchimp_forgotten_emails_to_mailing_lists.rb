# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddMailchimpForgottenEmailsToMailingLists < ActiveRecord::Migration[6.1]
  def change
    change_table(:mailing_lists) do |t|
      t.text :mailchimp_forgotten_emails
    end
  end
end
