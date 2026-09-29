# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "mailing_lists/_form.html.haml" do
  let(:entry) { mailing_lists(:leaders) }

  let(:ability) { Object.new.extend(CanCan::Ability) }

  before do
    allow(view).to receive_messages({
      model_class: MailingList,
      entry: entry,
      path_args: [entry.group, entry]
    })
    allow(view.controller).to receive(:current_ability).and_return(ability)
    assign(:preferred_label_categories, MailingList.preferred_label_categories)
    assign(:preferred_labels, entry.preferred_labels)
    assign(:legacy_preferred_labels, [])
    assign(:preferred_label_options, MailingList.preferred_label_categories.map { |c| [c.to_s, c.key] })
  end

  subject { Capybara::Node::Simple.new(render) }

  context "preferred_labels field" do
    it "renders a tom-select multi-select over the available categories" do
      expect(subject).to have_selector(
        'select[multiple][data-controller="tom-select"][name="mailing_list[preferred_labels][]"] ' \
        "option", text: "Andere"
      )
    end

    it "keeps unresolved legacy labels selectable" do
      assign(:legacy_preferred_labels, ["legacy-label"])
      assign(:preferred_labels, entry.preferred_labels + ["legacy-label"])
      assign(:preferred_label_options,
        MailingList.preferred_label_categories.map { |c| [c.to_s, c.key] } + [["legacy-label", "legacy-label"]])

      expect(subject).to have_selector(
        'select[name="mailing_list[preferred_labels][]"] option[selected]', text: "legacy-label"
      )
    end
  end

  context "subscribable_for fields" do
    it "are rendered if user can update attribute" do
      ability.can :update_subscriptions, entry

      expect(subject).to have_selector 'input[type=radio][name="mailing_list[subscribable_for]"]'
    end

    it "are not rendered if user cannot update attribute" do
      ability.cannot :update_subscriptions, entry

      expect(subject).to have_no_selector 'input[type=radio][name="mailing_list[subscribable_for]"]'
    end
  end

  context "subscribable_mode fields" do
    it "are rendered if user can update attribute and list is subscribable" do
      allow(entry).to receive(:subscribable_for_configured?).and_return(true)
      ability.can :update_subscriptions, entry

      expect(subject).to have_selector 'input[type=radio][name="mailing_list[subscribable_mode]"]'
    end

    it "are not rendered if user can update attribute but list is not subscribable" do
      allow(entry).to receive(:subscribable_for_configured?).and_return(false)
      ability.can :update_subscriptions, entry

      expect(subject).to have_no_selector 'input[type=radio][name="mailing_list[subscribable_mode]"]'
    end

    it "are not rendered if user cannot update attribute even if list is subscribable" do
      allow(entry).to receive(:subscribable_for_configured?).and_return(true)
      ability.cannot :update_subscriptions, entry

      expect(subject).to have_no_selector 'input[type=radio][name="mailing_list[subscribable_mode]"]'
    end

    it "are not rendered if user cannot update attribute and list is not subscribable" do
      allow(entry).to receive(:subscribable_for_configured?).and_return(false)
      ability.cannot :update_subscriptions, entry

      expect(subject).to have_no_selector 'input[type=radio][name="mailing_list[subscribable_mode]"]'
    end
  end
end
