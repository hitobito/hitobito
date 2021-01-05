# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::LoginMailer do

  let(:sender) { people(:top_leader) }
  let(:recipient) { people(:bottom_member) }
  let(:mail) { Person::LoginMailer.login(recipient, sender, 'abcdef') }

  subject { mail }

  its(:to)       { should == [recipient.email] }
  its(:reply_to) { should == [sender.email] }
  its(:subject)  { should == "Willkommen bei #{Settings.application.name}" }
  its(:body)     { should =~ /Hallo Bottom<br>.*test.host\/users\/password\/edit\?reset_password_token=/ }

  context 'with additional emails' do
    it 'does not send to them' do
      Fabricate(:additional_email, contactable: recipient)
      expect(mail.to).to eq [recipient.email]
    end
  end

  context 'with internationalized domain names' do
    before do
     recipient.update!(email: 'member@exämple.com')
     sender.update!(email: 'leader@exämple.com')
   end

    its(:to) { should == %w(member@xn--exmple-cua.com) }
    its(:reply_to) { should == %w(leader@xn--exmple-cua.com) }
  end

end
