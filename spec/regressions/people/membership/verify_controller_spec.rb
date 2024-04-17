# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe People::Membership::VerifyController, type: :controller do

  render_views

  let(:person) { people(:bottom_member) }
  let(:verify_token) { person.membership_verify_token }
  let(:dom) { Capybara::Node::Simple.new(response.body) }
  before do
    top_layer = groups(:top_layer)
    top_layer.update!(address: 'Muhrgasse 42a', zip_code: '4242', town: 'Romyland')
  end

  describe 'GET #show' do
    it 'returns 404 if feature not enabled' do
      get :show, params: { verify_token: verify_token }

      expect(response.status).to eq 404
    end

    context 'with feature enabled' do
      before { allow(People::MembershipVerifier).to receive(:enabled?).and_return(true) }

      it 'confirms active membership' do
        People::MembershipVerifier.any_instance.stub(:member?).and_return(true)

        get :show, params: { verify_token: verify_token }

        expect(dom).to have_selector('#membership-verify header #root-address strong', text: 'Top')
        expect(dom).to have_selector('#membership-verify header #root-address p', text: 'Muhrgasse 42a4242 Romyland')

        expect(dom).to have_selector('#membership-verify #details #member-name', text: 'Bottom Member')
        expect(dom).to have_selector('#membership-verify #details .alert-success', text: 'Mitgliedschaft gültig')
        expect(dom).to have_selector('#membership-verify #details .alert-success span.fa-check')
      end

      it 'confirms invalid membership' do
        People::MembershipVerifier.any_instance.stub(:member?).and_return(false)

        get :show, params: { verify_token: verify_token }

        expect(dom).to have_selector('#membership-verify #details #member-name', text: 'Bottom Member')
        expect(dom).to have_selector('#membership-verify #details .alert-danger', text: 'Keine gültige Mitgliedschaft')
        expect(dom).to have_selector('#membership-verify #details .alert-danger span.fa-times-circle')
      end

      it 'returns 404 with not found text for non existent verify token' do
        get :show, params: { verify_token: 'gits-nid' }

        expect(dom).to have_selector('#membership-verify header #root-address strong', text: 'Top')
        expect(dom).to have_selector('#membership-verify header #root-address p', text: 'Muhrgasse 42a4242 Romyland')

        expect(dom).to have_selector('#membership-verify #details .alert-danger', text: 'Ungültiger Verifikationscode')
        expect(dom).to have_selector('#membership-verify #details .alert-danger span.fa-times-circle')
      end
    end
  end
end
