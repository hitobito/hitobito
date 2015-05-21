# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PeopleSerializer do

  let(:person) do
    p = people(:top_leader)
    Fabricate(:additional_email, contactable: p, public: true)
    Fabricate(:social_account, contactable: p, public: true)
    Fabricate(:social_account, contactable: p, public: false)
    p.decorate
  end

  let(:controller) { double().as_null_object }

  let(:serializer) { PersonSerializer.new(person, controller: controller)}
  let(:hash) { serializer.to_hash }

  subject { hash[:people].first }

  context 'with details' do
    before { allow(controller).to receive(:can?).and_return(true) }

    it 'has additional properties' do
      is_expected.to have_key(:birthday)
      is_expected.to have_key(:gender)
    end

    it 'has all accounts' do
      links = subject[:links]
      expect(links[:social_accounts].size).to eq(2)
      expect(links[:additional_emails].size).to eq(1)
      expect(links).not_to have_key(:phone_numbers)
    end

    it 'does not contain login credentials' do
      is_expected.not_to have_key(:password)
      is_expected.not_to have_key(:encrypted_password)
      is_expected.not_to have_key(:authentication_token)
    end
  end

  context 'without details' do
    before { allow(controller).to receive(:can?).and_return(false) }

    it 'has additional properties' do
      is_expected.not_to have_key(:birthday)
      is_expected.not_to have_key(:gender)
    end

    it 'has only public accounts' do
      links = subject[:links]
      expect(links[:social_accounts].size).to eq(1)
      expect(links[:additional_emails].size).to eq(1)
      expect(links).not_to have_key(:phone_numbers)
    end
  end

end