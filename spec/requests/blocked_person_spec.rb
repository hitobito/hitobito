# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

RSpec.describe 'reject_blocked_person!', type: :request do
  let(:person) { people(:bottom_member) }
  let(:group) { groups(:bottom_layer_one) }

  before { sign_in(person) }

  describe 'blocked routes' do
    context 'with not blocked person' do
      it { expect(get root_path).not_to redirect_to(blocked_path) }
      it { expect(get group_path(group)).not_to redirect_to(blocked_path) }
    end

    context 'with blocked person' do
      before { Person::BlockService.new(person).block! }

      it { expect(get root_path).to redirect_to(blocked_path) }
      it { expect(get group_path(group)).to redirect_to(blocked_path) }
    end
  end

  describe 'blocked routes' do
    context 'with blocked person' do
      before { Person::BlockService.new(person).block! }

      it { expect(get new_person_session_path).not_to redirect_to(blocked_path) }
      it { expect(delete destroy_person_session_path).not_to redirect_to(blocked_path) }
    end
  end
end
