# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Devise::Hitobito::PasswordsController do
  let(:bottom_group) { groups(:bottom_group_one_one) }

  before do
    request.env['devise.mapping'] = Devise.mappings[:person]
    ActionMailer::Base.deliveries = []
  end

  describe '#create' do
    it '#create with invalid email invalid password' do
      post :create, params: { person: { email: 'asdf' } }
      expect(last_email).not_to be_present
      expect(controller.send(:resource).errors[:email]).to eq ['nicht gefunden']
    end

    context 'with login permission' do
      let(:person) { Fabricate('Group::BottomGroup::Leader', group: bottom_group).person.reload }

      it '#create shows invalid password' do
        post :create, params: { person: { email: person.email } }
        expect(flash[:notice]).to eq 'Du erhältst in wenigen Minuten eine E-Mail mit der Anleitung, wie Du Dein Passwort zurücksetzen kannst.'
        expect(last_email).to be_present
      end
    end

    context 'without login permission' do
      it '#create shows invalid password' do
        post :create, params: { person: { email: 'not-existing@example.com' } }
        expect(last_email).not_to be_present
        expect(flash[:alert]).to eq  'Du bist nicht berechtigt, Dich hier anzumelden.'
      end
    end

    def last_email
      ActionMailer::Base.deliveries.last
    end
  end

end
