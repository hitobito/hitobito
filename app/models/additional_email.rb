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
#  contactable_id   :integer          not null
#  contactable_type :string(255)      not null
#  email            :string(255)      not null
#  label            :string(255)
#  public           :boolean          default(TRUE), not null
#  mailings         :boolean          default(TRUE), not null
#

class AdditionalEmail < ActiveRecord::Base

  include ContactAccount

  self.value_attr = :email

  validates :email, format: Devise.email_regexp

  class << self
    def predefined_labels
      Settings.additional_email.predefined_labels
    end

    def mailing_emails_for(people)
      where(contactable_id: people.collect(&:id),
            contactable_type: Person.sti_name,
            mailings: true).
      pluck(:email)
    end
  end

end
