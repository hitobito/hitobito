# encoding: utf-8
# == Schema Information
#
# Table name: custom_contents
#
#  id                    :integer          not null, primary key
#  key                   :string(255)      not null
#  placeholders_required :string(255)
#  placeholders_optional :string(255)
#


#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
require 'spec_helper'

describe CustomContent do

  subject { custom_contents(:login) }

  context '.list' do
    it 'contains one entry per main item' do
      CustomContent.list.should have(2).items
    end
  end

  context 'lists' do
    it 'creates empty list for nil' do
      custom_contents(:notes).placeholders_required_list.should == []
    end

    it 'creates list with one element' do
      subject.placeholders_required_list.should == ['login-url']
    end

    it 'creates list with several elements' do
      subject.placeholders_required = 'login-url, foo ,bar'
      subject.placeholders_required_list.should == %w(login-url foo bar)
    end
  end

  context 'validations' do
    it 'succeeds without defined placeholders' do
      cc = custom_contents(:notes)
      cc.should be_valid
    end

    it 'succeeds with only optional placeholders' do
      subject.placeholders_required = nil
      should be_valid
    end

    it 'fail if one required placeholder is missing' do
      subject.placeholders_required = 'login-url, sender'
      should_not be_valid
    end

    it 'succeeds if all required placeholders are used' do
      should be_valid
    end
  end

  context '#body_with_values' do
    it 'replaces all placeholders' do
      subject.body = 'Hello {user}, here is your site to login: {login-url}. Goodbye {user}'
      output = subject.body_with_values('user' => 'Fred', 'login-url' => 'example.com/login')
      output.should == 'Hello Fred, here is your site to login: example.com/login. Goodbye Fred'
    end

    it 'handles contents without placeholders' do
      custom_contents(:notes).body_with_values.should == 'Bla bla bla bla'
    end

    it 'raises an error if placeholder is missing' do
      expect { subject.body_with_values('login-url' => 'example.com/login') }.to raise_error(KeyError)
    end

    it 'raises an error if non-defined placeholder is given' do
      expect { custom_contents(:notes).body_with_values('foo' => 'bar') }.to raise_error(ArgumentError)
    end

    it 'does not care about unused placeholders' do
      subject.body = 'Hello You, here is your site to login: {login-url}'
      output = subject.body_with_values('user' => 'Fred', 'login-url' => 'example.com/login')
      output.should == 'Hello You, here is your site to login: example.com/login'
    end
  end

end
