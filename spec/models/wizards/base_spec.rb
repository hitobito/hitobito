# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wizards::Base do
  before do
    stub_const("One", Class.new(Wizards::Step))
    stub_const("Two", Class.new(Wizards::Step))
    stub_const("Three", Class.new(Wizards::Step))
    stub_const("Wizard", Class.new(Wizards::Base))
  end

  subject(:wizard) { Wizard.new(current_step: 0) }

  let(:steps) { wizard.send(:step_instances) }

  describe "SingleStepWizard" do
    before { Wizard.steps = [One] }

    it "has single step" do
      expect(wizard.steps).to eq [One]
      expect(wizard.class.steps).to eq [One]
    end

    it "has single step derived partial" do
      expect(wizard.partials).to eq ["one"]
    end

    it "knows it is on first and last step" do
      expect(wizard).to be_first_step
      expect(wizard).to be_last_step
    end

    it "step_at finds step at index" do
      expect(wizard.step_at(0)).to eq steps.first
      expect(wizard.step_at(1)).to be_nil
    end

    it "can access step via method missing" do
      expect(wizard.one).to be_kind_of(One)
    end

    it "can access step via step method" do
      expect(wizard.step("one")).to be_kind_of(One)
    end

    it "raises when accessing non existing step" do
      expect { wizard.one_two }.to raise_error(NoMethodError)
    end

    it "valid? is true if step is valid" do
      expect(steps.first).to receive(:valid?).and_return(true)
      expect(wizard).to be_valid
    end

    it "valid? is false if step is invalid" do
      expect(steps.first).to receive(:valid?).and_return(false)
      expect(wizard).not_to be_valid
    end

    it "save! raises if step is invalid" do
      expect(steps.first).to receive(:valid?).and_return(false)
      expect { wizard.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "save! is true if step is valid " do
      expect(steps.first).to receive(:valid?).and_return(true)
      expect(wizard.save!).to eq true
    end
  end

  describe "MultiStepWizard" do
    before { Wizard.steps = [One, Two] }

    it "has two steps" do
      expect(wizard.steps).to eq [One, Two]
      expect(wizard.class.steps).to eq [One, Two]
    end

    it "knows it is on first but not on last step" do
      expect(wizard).to be_first_step
      expect(wizard).not_to be_last_step
    end

    it "move_on moves to next step" do
      expect { wizard.move_on }.to change { wizard.current_step }.by(1)
      expect(wizard.step_at(wizard.current_step)).to be_instance_of(Two)
      expect(wizard).not_to be_first_step
      expect(wizard).to be_last_step
    end

    it "move_on noops if current step is invalid" do
      expect(steps.first).to receive(:valid?).and_return(false)
      expect { wizard.move_on }.not_to(change { wizard.current_step })
      expect(wizard).to be_first_step
    end

    it "valid? ignores steps after current step" do
      expect(steps.first).to receive(:valid?).and_return(true)
      expect(steps.second).not_to receive(:valid?)
      expect(wizard).to be_valid
    end

    it "valid? validates up to current step returing false if last step is invalid" do
      wizard.move_on

      expect(steps.first).to receive(:valid?).and_return(true)
      expect(steps.second).to receive(:valid?).and_return(false)
      expect(wizard).not_to be_valid
    end

    it "valid? validates up to current step returing true if last step is valid" do
      wizard.move_on

      expect(steps.first).to receive(:valid?).and_return(true)
      expect(steps.second).to receive(:valid?).and_return(true)
      expect(wizard).to be_valid
    end

    it "save! raises if not on last step" do
      expect do
        wizard.save!
      end.to raise_error(RuntimeError, "do not call #save! before the last step")
    end

    it "save! validates all if on last step" do
      wizard.move_on

      expect(steps.first).to receive(:valid?).and_return(false)
      expect(steps.first).not_to receive(:valid?)
      expect { wizard.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "save! validates all steps and succeeds" do
      wizard.move_on
      expect(steps.first).to receive(:valid?).and_return(true)
      expect(steps.second).to receive(:valid?).and_return(true)
      expect(wizard.save!).to eq true
    end
  end

  describe "::step_after" do
    before { Wizard.steps = [One, Two, Three] }

    it "finds next step" do
      expect(Wizard.step_after(:_start)).to eq "one"
      expect(Wizard.step_after(One)).to eq "two"
      expect(Wizard.step_after(Two)).to eq "three"
      expect(Wizard.step_after(Three)).to be_nil
    end

    it "finds next step with symbol" do
      expect(Wizard.step_after(:_start)).to eq "one"
      expect(Wizard.step_after(:one)).to eq "two"
      expect(Wizard.step_after(:two)).to eq "three"
      expect(Wizard.step_after(:three)).to be_nil
    end
  end

  describe "Step order" do
    before { Wizard.steps = [One, Two, Three] }

    it "by default builds steps in order as defined" do
      expect(steps.map(&:class)).to eq [One, Two, Three]
    end

    it "step order can be customized by overriding #step_after" do
      allow(wizard).to receive(:step_after) do |s|
        case s
        when :_start then :three
        when :three then :one
        end
      end

      expect(steps.map(&:class)).to eq [Three, One]
    end
  end
end
