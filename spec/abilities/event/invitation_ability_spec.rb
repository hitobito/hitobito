#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

require "spec_helper"

describe Event::InvitationAbility do
  let(:invitee) { Fabricate(:person) }
  let(:manager) { Fabricate(:person) }
  let!(:manager_relation) { PeopleManager.create(manager: manager, managed: invitee) }

  let(:course) { Fabricate(:course) }
  let(:invitation) { Fabricate(:event_invitation, event: course, person: invitee) }

  subject { Ability.new(user) }

  context "decline" do
    context "for self" do
      let(:user) { invitee }

      it { is_expected.to be_able_to :decline, invitation }
    end

    context "for manager" do
      let(:user) { manager }

      it { is_expected.to be_able_to :decline, invitation }
    end

    context "for unrelated user" do
      let(:user) { Fabricate(:person) }

      it { is_expected.not_to be_able_to :decline, invitation }
    end
  end
end
