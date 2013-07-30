# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe  Import::PersonColumnGuesser do

  let(:headers) { ['Geschlecht', 'vorname', 'Name', 'skype'] }
  let(:guesser) { Import::PersonColumnGuesser.new(headers, params) }
  let(:nil_key) { { key: nil } }
  let(:params) { {} }

  context "maps default values for header" do
    subject { guesser.mapping }

    its(['Geschlecht']) { should eq field_for(:gender) }
    its(['vorname']) { should eq field_for(:first_name) }
    its(['skype']) { should eq field_for(:social_account_skype) }

    context "maps first occurance from Import::Person.fields" do
      its(['Name']) { should eq field_for(:company_name) }
    end

    context "handles noexisting headers" do
      let(:headers) { ["Geburtsdatum", "Email"] }

      its(['Geburtsdatum']) { should eq nil_key }
      its(['Email']) { should eq nil_key }
    end

    context "params override mapping" do
      let(:params) { { "Name" => "first_name" } }

      its(['Name']) { should eq field_for(:first_name) }
    end
  end


  def field_for(key)
    field = Import::Person.fields.find { |f| f[:key] == key.to_s }
    raise "no Person field found for #{key}" if !field
    field
  end

end
