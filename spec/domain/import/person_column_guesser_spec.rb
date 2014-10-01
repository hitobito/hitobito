# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe  Import::PersonColumnGuesser do

  let(:headers) { %w(Geschlecht vorname Name skype) }
  let(:guesser) { Import::PersonColumnGuesser.new(headers, params) }
  let(:nil_key) { { key: nil } }
  let(:params) { {} }

  subject { guesser.mapping }

  context 'maps default values for header' do
    its(['Geschlecht']) { should eq field_for(:gender) }
    its(['vorname']) { should eq field_for(:first_name) }
    its(['skype']) { should eq field_for(:social_account_skype) }


    context 'handles noexisting headers' do
      let(:headers) { %w(Geburtsdatum Email) }

      its(['Geburtsdatum']) { should eq nil_key }
      its(['Email']) { should eq nil_key }
    end

    context 'params override mapping' do
      let(:params) { { 'Name' => 'first_name' } }
      its(['Name']) { should eq field_for(:first_name) }
    end
  end

  context 'matching' do
    before do
      Import::Person.stub(fields: [
        {key: 'other_name', value: 'Anderer Name'},
        {key: 'name', value: 'Name'}
      ])
    end

    context 'uses first exact matched value' do
      let(:headers) { %w(Name) }
      its(['Name']) { should eq field_for(:name) }
    end

    context 'falls back first partial matched value if no exact match found' do
      let(:headers) { %w(ame) }
      its(['ame']) { should eq field_for(:other_name) }
    end
  end


  def field_for(key)
    field = Import::Person.fields.find { |f| f[:key] == key.to_s }
    fail "no Person field found for #{key}" if !field
    field
  end

end
