#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

require "spec_helper"

describe Event::ParticipationContactDataAbility do
  let(:participant) { Fabricate(:person) }
  let(:manager) { Fabricate(:person) }
  let!(:manager_relation) { PeopleManager.create(manager: manager, managed: participant) }

  let(:course) { Fabricate(:course) }
  let(:participation) { Fabricate(:event_participation, event: course, person: participant) }
  let(:attributes) do
    h = ActiveSupport::HashWithIndifferentAccess.new
    h.merge({first_name: "John", last_name: "Gonzales",
              email: "somebody@example.com",
              nickname: ""})
  end
  let(:participation_contact_data) { Event::ParticipationContactData.new(course, participant, attributes) }

  subject { Ability.new(user) }

  [:show, :update].each do |ability|
    context ability.to_s do
      context "for self" do
        let(:user) { participant }

        it { is_expected.to be_able_to ability, participation_contact_data }
      end

      context "for manager" do
        let(:user) { manager }

        it { is_expected.to be_able_to ability, participation_contact_data }
      end

      context "for unrelated user" do
        let(:user) { Fabricate(:person) }

        it { is_expected.not_to be_able_to ability, participation_contact_data }
      end
    end
  end
end
