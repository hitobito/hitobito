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
      should have_key(:birthday)
      should have_key(:gender)
    end

    it 'has all accounts' do
      links = subject[:links]
      links[:social_accounts].should have(2).items
      links[:additional_emails].should have(1).items
      links.should_not have_key(:phone_numbers)
    end

    it 'does not contain login credentials' do
      should_not have_key(:password)
      should_not have_key(:encrypted_password)
      should_not have_key(:authentication_token)
    end
  end

  context 'without details' do
    before { allow(controller).to receive(:can?).and_return(false) }

    it 'has additional properties' do
      should_not have_key(:birthday)
      should_not have_key(:gender)
    end

    it 'has only public accounts' do
      links = subject[:links]
      links[:social_accounts].should have(1).items
      links[:additional_emails].should have(1).items
      links.should_not have_key(:phone_numbers)
    end
  end

end