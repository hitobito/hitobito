# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: mailing_lists
#
#  id                   :integer          not null, primary key
#  name                 :string(255)      not null
#  group_id             :integer          not null
#  description          :text(65535)
#  publisher            :string(255)
#  mail_name            :string(255)
#  additional_sender    :string(255)
#  subscribable         :boolean          default(FALSE), not null
#  subscribers_may_post :boolean          default(FALSE), not null
#  anyone_may_post      :boolean          default(FALSE), not null
#  delivery_report      :boolean          default(FALSE), not null
#  preferred_labels     :string(255)
#  main_email           :boolean          default(FALSE)
#

Fabricator(:mailing_list) do
  name { Faker::Company.name }
  subscriptions(count: 1)
  mailchimp_api_key "1234567890d66d25cc5c9285ab5a5552-us12"
  mailchimp_list_id "123456789"
end
