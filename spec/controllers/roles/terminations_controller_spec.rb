# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Roles::TerminationsController do
  let(:role) { roles(:bottom_member) }

  context 'unauthorized' do
    it 'redirects to root_path' do
      post :create,
           params: { group_id: role.group_id, role_id: role.id,
                     roles_termination: { terminate_on: 1.month.from_now } }
      expect(response).to redirect_to %r{/users/sign_in}
    end
  end

  context 'authorized' do
    before { sign_in(role.person) }

    let(:terminate_on) { 1.month.from_now.to_date }
    let(:params) do
      { group_id: role.group_id, role_id: role.id,
        roles_termination: { terminate_on: terminate_on } }
    end

    let(:termination) do
      instance_double(
        'Roles::Termination',
        valid?: true,
        terminate_on: terminate_on
      )
    end
    before { expect(termination).to receive(:call).and_return(true) }

    context 'POST create' do
      it 'builds Roles::Termination with params and calls #call' do
        expect(Roles::Termination).
          to receive(:new).with(role: role,
                                terminate_on: terminate_on.strftime('%Y-%m-%d')).and_return(termination)

        post :create, params: params, format: :js
      end

      it 'ignores terminate_on if role has delete_on set' do
        delete_on = 1.month.from_now.to_date
        role.update!(delete_on: delete_on)

        expect(Roles::Termination).
          to receive(:new).with(role: role,
                                terminate_on: delete_on).and_return(termination)

        post :create, params: params, format: :js
      end
    end
  end
end
