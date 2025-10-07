#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

require "spec_helper"

describe Event::ApplicationAbility do
  let(:applicant) { Fabricate(:person) }
  let(:manager) { Fabricate(:person) }
  let!(:manager_relation) { PeopleManager.create(manager: manager, managed: applicant) }

  let(:course) { Fabricate(:course) }
  let(:application) { Fabricate(:event_application, priority_1: course, priority_2: nil) }
  let!(:participation) { Fabricate(:event_participation, event: course, application: application, participant: applicant) }

  subject { Ability.new(user) }

  [:show_priorities, :show_approval].each do |ability|
    context ability.to_s do
      context "for self" do
        let(:user) { applicant }

        it { is_expected.to be_able_to ability, application }
      end

      context "for manager" do
        let(:user) { manager }

        it { is_expected.to be_able_to ability, application }
      end

      context "for unrelated user" do
        let(:user) { Fabricate(:person) }

        it { is_expected.not_to be_able_to ability, application }
      end
    end
  end
end
