# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "person/subscriptions/index.html.haml" do
  let(:current_user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:list) { mailing_lists(:leaders) }

  before do
    allow(view).to receive(:can?)
    allow(view).to receive(:subscribed).and_return([])
    allow(view).to receive(:person).and_return(person)
    allow(view).to receive(:subscribable).and_return({group => [list]})
    allow_any_instance_of(MailingListsHelper).to receive(:current_user).and_return(person)
  end

  subject { Capybara::Node::Simple.new(render) }

  it "renders subscribe button if permitted" do
    allow(view).to receive(:can?).with(:update, person).and_return(true)
    expect(subject).to have_link "Anmelden", href: group_person_subscriptions_path(list.group, person, id: list.id)
  end

  it "does not render subscribe button if not permitted" do
    allow(view).to receive(:can?).with(:update, person).and_return(false)
    expect(subject).to have_selector "td strong", text: list.name
    expect(subject).not_to have_link "Anmelden"
  end

  context "viewing someone else" do
    let(:person) { people(:bottom_member) }

    it "renders subscribe button if permitted" do
      allow(view).to receive(:can?).with(:update, person).and_return(true)
      expect(subject).to have_link "Anmelden", href: group_person_subscriptions_path(list.group, person, id: list.id)
    end
  end
end
