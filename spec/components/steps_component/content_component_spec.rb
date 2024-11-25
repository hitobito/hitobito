# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe StepsComponent::ContentComponent, type: :component do
  let(:step) { SimpleStep.new({}) }
  let(:wizard) { Wizards::Base.new(current_step: 0) }
  let(:form) { double(:form, object: wizard) }
  let(:iterator) { double(:iterator, index: 0, last?: false) }

  subject(:component) do
    described_class.new(partial: :partial, partial_iteration: iterator, form: form, step: 0)
  end

  subject(:content) { Capybara::Node::Simple.new(render_inline(component)) }

  context "conditional rendering of step content" do
    before do
      stub_const("SimpleStep", Class.new(Wizards::Step) do
        attribute :name, type: :string, default: "name"
      end)
      allow(component).to receive(:markup) do
        step.name
      end
    end

    it "renders step name wrapped in div" do
      expect(content).to have_css "div[data-steps-component-target]", class: "step-content partial active", text: "name"
    end

    describe "second step" do
      before do
        allow(wizard).to receive(:step_at).with(1).and_return(step)
        allow(iterator).to receive(:index).and_return(1)
      end

      it "does not render component if index is greater than step" do
        expect(render_inline(component).to_s).to be_blank
      end

      it "does not render component if index is greater than step but step has value set" do
        step.name = "dummy"
        expect(render_inline(component).to_s).not_to be_blank
        expect(content).to have_css "div[data-steps-component-target]", class: "step-content partial", text: "dummy"
      end
    end
  end

  it "back link renders link for stimulus controller iterator based index" do
    expect(component).to receive(:markup) do
      component.back_link
    end
    back_link = Capybara::Node::Simple.new(render_inline(component))
    expect(back_link).to have_link "Zurück"
    expect(back_link).to have_css ".link.cancel[data-index=-1]", text: "Zurück"
    expect(back_link).to have_css ".link.cancel[data-action='steps-component#back']",
      text: "Zurück"
  end

  it "next button renders form button with step value" do
    allow_any_instance_of(StepsComponent::ContentComponent).to receive(:past?).and_return(false)
    expect(component).to receive(:markup) do
      expect(form).to receive(:button)
        .with("Weiter",
          {class: "btn btn-sm btn-primary mt-2",
           data: {disable_with: "Weiter"}, name: :next, type: "submit", value: 1})
      component.next_button
    end
    render_inline(component)
  end

  it "next button accepts specific label" do
    allow_any_instance_of(StepsComponent::ContentComponent).to receive(:past?).and_return(false)
    expect(component).to receive(:markup) do
      expect(form).to receive(:button)
        .with("Test",
          {class: "btn btn-sm btn-primary mt-2",
           data: {disable_with: "Test"}, name: :next, type: "submit", value: 1})
      component.next_button("Test")
    end
    render_inline(component)
  end

  context "real partial" do
    let(:group) { groups(:top_group) }
    let(:wizard) { Wizards::RegisterNewUserWizard.new(group: group) }
    let(:form) do
      StandardFormBuilder.new(:wizard, wizard, vc_test_controller.view_context, {builder: StandardFormBuilder})
    end
    let(:component) do
      described_class.new(partial: wizard.new_user_form.partial, partial_iteration: iterator, form: form, step: 0)
    end
    let(:iterator) { double(:iterator, index: 0, last?: false) }
    let(:policy_finder) { double(:policy_finder, acceptance_needed?: true, groups: []) }

    subject(:html) { render_inline(component) }

    before do
      allow(wizard).to receive(:policy_finder).and_return(policy_finder)
      allow_any_instance_of(ActionView::Base).to receive(:policy_finder).and_return(policy_finder)
    end

    it "renders first_name last_name and email" do
      expect(html).to have_field("Haupt-E-Mail")
      expect(html).to have_field("Vorname")
      expect(html).to have_field("Nachname")
      expect(html).to have_field("Firma")
    end

    it "hides company if flag is set" do
      allow(Wizards::Steps::NewUserForm).to receive(:support_company).and_return(false)
      expect(html).to have_field("Haupt-E-Mail")
      expect(html).not_to have_field("Firma")
    end

    it "renders wizard and step errors" do
      wizard.errors.add(:base, "wizard error")
      wizard.step_at(0).errors.add(:base, "step error")
      expect(html).to have_css ".alert-danger li", text: "step error"
      expect(html).to have_css ".alert-danger li", text: "wizard error"
    end

    it "shows check if policy_finder needs acceptance" do
      expect(policy_finder).to receive(:acceptance_needed?).and_return(true)
      expect(html).to have_field("Haupt-E-Mail")
      expect(html).to have_field("Ich erkläre mich mit den folgenden Bestimmungen einverstanden:")
    end

    it "hides check if policy_finder needs acceptance but we are not on the last page" do
      expect(wizard).to receive(:steps).and_return([:one, :two])
      expect(html).to have_field("Haupt-E-Mail")
      expect(html).not_to have_field("Ich erkläre mich mit den folgenden Bestimmungen einverstanden:")
    end
  end
end
