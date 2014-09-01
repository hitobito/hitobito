# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe ContactableDecorator do
  before do
    Draper::ViewContext.clear!
    group = Group.new(id: 1, name: 'foo', address: 'foostreet 3', zip_code: '4242', town: 'footown', email: 'foo@foobar.com', country: 'Schweiz')
    group.phone_numbers.new(number: '031 12345', label: 'Home', public: true)
    group.phone_numbers.new(number: '041 12345', label: 'Work', public: true)
    group.phone_numbers.new(number: '079 12345', label: 'Mobile', public: false)
    group.social_accounts.new(name: 'www.puzzle.ch', label: 'link1')
    group.social_accounts.new(name: 'http://puzzle.ch', label: 'link2')
    group.social_accounts.new(name: 'bad.website.link', label: 'bad link1')
    group.social_accounts.new(name: 'www.', label: 'bad link2')
    group.additional_emails.new(email: 'additional@foobar.com', label: 'Work', public: true, mailings: true)
    group.additional_emails.new(email: 'private@foobar.com', label: 'Mobile', public: false)
    @group = GroupDecorator.decorate(group)
  end

  it '#complete_address' do
    @group.complete_address.should eq '<p>foostreet 3<br />4242 footown</p>'
  end

  it '#primary_email' do
    @group.primary_email.should eq '<p><a href="mailto:foo@foobar.com">foo@foobar.com</a></p>'
  end

  context '#all_emails' do
    subject { @group.all_emails }

    it { should =~ /foo@foobar.com/ }
    it { should =~ /additional@foobar.com.+Work/ }
    it { should_not =~ /private@foobar.com.+Mobile/ }
  end

  context '#all_additional_emails' do
    context 'only public' do
      subject { @group.all_additional_emails }

      it { should =~ /additional@foobar.com.+Work/ }
      it { should_not =~ /private@foobar.com.+Mobile/ }
    end

    context 'all' do
      subject { @group.all_additional_emails(false) }

      it { should =~ /additional@foobar.com.+Work/ }
      it { should =~ /private@foobar.com.+Mobile/ }
    end
  end

  context '#all_phone_numbers' do
    context 'only public' do
      subject { @group.all_phone_numbers }

      it { should =~ /031.*Home/ }
      it { should =~ /041.*Work/ }
      it { should_not =~ /079.*Mobile/ }
    end

    context 'all' do
      subject { @group.all_phone_numbers(false) }

      it { should =~ /031.*Home/ }
      it { should =~ /041.*Work/ }
      it { should =~ /079.*Mobile/ }
    end
  end

  context '#all_social_accounts' do
    context 'web links' do
      subject { @group.all_social_accounts }

      it { should =~ /www.puzzle.ch<\/a>/ }
      it { should =~ /http:\/\/puzzle.ch<\/a>/ }
      it { should_not =~ /bad.website.link<\/a>/ }
      it { should_not =~ /www.<\/a>/ }

    end
  end

  context 'addresses' do
    context 'country' do
      it "shouldn't print country ch/schweiz" do
        @group.complete_address.should_not =~ /Schweiz/
      end

      it 'should print country' do
        @group.country = 'the ultimate country'
        @group.complete_address.should =~ /the ultimate country/
      end
    end
  end

end
