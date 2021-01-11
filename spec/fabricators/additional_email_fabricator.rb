# encoding: utf-8

#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: additional_emails
#
#  id               :integer          not null, primary key
#  contactable_type :string(255)      not null
#  email            :string(255)      not null
#  label            :string(255)
#  mailings         :boolean          default(FALSE), not null
#  public           :boolean          default(TRUE), not null
#  contactable_id   :integer          not null
#
# Indexes
#
#  index_additional_emails_on_contactable_id_and_contactable_type  (contactable_id,contactable_type)
#

Fabricator(:additional_email) do
  contactable { Fabricate(:person) }
  email { "#{Faker::Internet.user_name}@hitobito.example.com" }
  label { 'Privat' }
end
