# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'


describe Export::Csv::People::ContactAccounts do

  subject { Export::Csv::People::ContactAccounts }

  context 'phone_numbers' do
    it 'creates standard key and human translations' do
      subject.key(PhoneNumber, 'foo').should eq :phone_number_foo
      subject.human(PhoneNumber, 'foo').should eq 'Telefonnummer foo'
    end
  end

  context 'social_accounts' do
    it 'creates standard key and human translations' do
      subject.key(SocialAccount, 'foo').should eq :social_account_foo
      subject.human(SocialAccount, 'foo').should eq 'Social Media Adresse foo'
    end
  end
end
