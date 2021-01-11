# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: mailing_lists
#
#  id                                  :integer          not null, primary key
#  additional_sender                   :string(255)
#  anyone_may_post                     :boolean          default(FALSE), not null
#  delivery_report                     :boolean          default(FALSE), not null
#  description                         :text(16777215)
#  mail_name                           :string(255)
#  mailchimp_api_key                   :string(255)
#  mailchimp_include_additional_emails :boolean          default(FALSE)
#  mailchimp_last_synced_at            :datetime
#  mailchimp_result                    :text(16777215)
#  mailchimp_syncing                   :boolean          default(FALSE)
#  main_email                          :boolean          default(FALSE)
#  name                                :string(255)      not null
#  preferred_labels                    :string(255)
#  publisher                           :string(255)
#  subscribable                        :boolean          default(FALSE), not null
#  subscribers_may_post                :boolean          default(FALSE), not null
#  group_id                            :integer          not null
#  mailchimp_list_id                   :string(255)
#
# Indexes
#
#  index_mailing_lists_on_group_id  (group_id)
#

Fabricator(:mailing_list) do
  name { Faker::Company.name }
end
