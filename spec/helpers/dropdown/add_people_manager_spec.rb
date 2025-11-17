require "spec_helper"

describe Dropdown::AddPeopleManager do
  include FormatHelper
  include LayoutHelper
  include UtilityHelper
  include I18nHelper

  let(:ability) { Ability.new(people(:top_leader)) }
  let(:person) { people(:bottom_member) }

  subject(:html) { Capybara::Node::Simple.new(dropdown.to_s) }

  subject(:dropdown) { described_class.new(self, person) }

  delegate :can?, :cannot?, to: :ability

  before do
    allow(FeatureGate).to receive(:enabled?).and_return(true)
  end

  it "renders dropdown toggle with 3 links" do
    expect(html).to have_css("a", count: 3)
    expect(html).to have_link "Erstellen", class: "dropdown-toggle"
    expect(html).to have_link "Verwalter*in zuweisen", class: "dropdown-item", href: new_person_manager_path(person)
    expect(html).to have_link "Kind zuweisen", class: "dropdown-item", href: new_person_managed_path(person)
  end

  context "when ability user and person are identical" do
    let(:person) { people(:top_leader) }

    it "renders single button only to assign new managed" do
      expect(html).to have_css("a", count: 1)
      expect(html).to have_link("Kind zuweisen", href: new_person_managed_path(person))
    end
  end

  context "when person has only read permissions" do
    let(:role) { Fabricate(Group::BottomGroup::Member.sti_name, group: groups(:bottom_group_one_one)) }
    let(:ability) { Ability.new(role.person) }

    it "renders nothing if creating assigned managed feature is disabled" do
      allow(FeatureGate).to receive(:enabled?).and_return(false)
      expect(dropdown.to_s).to be_blank
    end

    it "renders assign managed cannot lookup people and create feature gate is enabled" do
      allow(FeatureGate).to receive(:enabled?).and_return(true)
      expect(html).to have_css("a", count: 1)
      expect(html).to have_link("Kind erfassen", href: new_person_managed_path(person, create: true))
    end
  end
end
