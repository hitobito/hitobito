# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: social_accounts
#
#  id               :integer          not null, primary key
#  contactable_type :string(255)      not null
#  label            :string(255)
#  name             :string(255)      not null
#  public           :boolean          default(TRUE), not null
#  contactable_id   :integer          not null
#
# Indexes
#
#  index_social_accounts_on_contactable_id_and_contactable_type  (contactable_id,contactable_type)
#

class SocialAccount < ActiveRecord::Base

  include ContactAccount

  self.value_attr = :name


  validates_by_schema

  class << self
    def predefined_labels
      Settings.social_account.predefined_labels
    end
  end

end
