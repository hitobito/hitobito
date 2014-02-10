# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'


describe Export::Csv::People::Accounts do

  subject { Export::Csv::People::Accounts }

  context 'phone_numbers' do
    it 'creates standard key and human translations' do
      subject.phone_numbers.key('foo').should eq :phone_number_foo
      subject.phone_numbers.human('foo').should eq 'Telefonnummer Foo'
    end
  end

  context 'social_accounts' do
    it 'creates standard key and human translations' do
      subject.social_accounts.key('foo').should eq :social_account_foo
      subject.social_accounts.human('foo').should eq 'Social Media Adresse Foo'
    end
  end
end
