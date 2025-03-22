#  Copyright (c) 2012-2017, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Person subscriptions", js: true do
  subject { page }

  let(:group) { groups(:top_group) }
  let(:leader) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: group).person }
  let(:user) { leader }
  let(:person) { people(:top_leader) }
  let!(:layer_subscription) { Fabricate(:mailing_list, group: group, name: "Abo aus der Ebene", subscribable_for: :anyone) }
  let!(:other_subscription) { Fabricate(:mailing_list, group: groups(:toppers), name: "Abo aus anderer Ebene", subscribable_for: :anyone) }

  before do
    sign_in(user)
  end

  context "creation" do
    before do
      visit group_person_subscriptions_path(group_id: group.id, person_id: person.id)
    end

    it "before tabswitch" do
      expect(page).to have_text(layer_subscription.name)
      expect(page).to have_text(other_subscription.name)
    end

    it "after tabswitch" do
      click_link "Übergeordnete Abos anzeigen"
      expect(page).to have_text(layer_subscription.name)
      expect(page).not_to have_text(other_subscription.name)
    end
  end
end