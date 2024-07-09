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
    assign(:preferred_labels, [])
  end

  subject { Capybara::Node::Simple.new(render) }

  context "subscribable_for fields" do
    it "are rendered if user can update attribute" do
      ability.can :update, entry, :subscribable_for

      expect(subject).to have_selector 'input[type=radio][name="mailing_list[subscribable_for]"]'
    end

    it "are not rendered if user cannot update attribute" do
      ability.cannot :update, entry, :subscribable_for

      expect(subject).to have_no_selector 'input[type=radio][name="mailing_list[subscribable_for]"]'
    end
  end

  context "subscribable_mode fields" do
    it "are rendered if user can update attribute and list is subscribable" do
      allow(entry).to receive(:subscribable?).and_return(true)
      ability.can :update, entry, :subscribable_mode

      expect(subject).to have_selector 'input[type=radio][name="mailing_list[subscribable_mode]"]'
    end

    it "are not rendered if user can update attribute but list is not subscribable" do
      allow(entry).to receive(:subscribable?).and_return(false)
      ability.can :update, entry, :subscribable_mode

      expect(subject).to have_no_selector 'input[type=radio][name="mailing_list[subscribable_mode]"]'
    end

    it "are not rendered if user cannot update attribute even if list is subscribable" do
      allow(entry).to receive(:subscribable?).and_return(true)
      ability.cannot :update, entry, :subscribable_mode

      expect(subject).to have_no_selector 'input[type=radio][name="mailing_list[subscribable_mode]"]'
    end

    it "are not rendered if user cannot update attribute and list is not subscribable" do
      allow(entry).to receive(:subscribable?).and_return(false)
      ability.cannot :update, entry, :subscribable_mode

      expect(subject).to have_no_selector 'input[type=radio][name="mailing_list[subscribable_mode]"]'
    end
  end
end
