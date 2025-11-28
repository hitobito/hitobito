# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

module ChoiceForm
  describe Choice do
    describe "choice fallbacks" do
      let(:choice) { Choice.new(@choice_translations) }

      it "should use current locale when fallbacks are false" do
        stub_fallbacks(false)

        @choice_translations = {de: "", en: "", fr: "Fallback", it: ""}
        expect(choice.choice).to eql("")
      end

      it "should use current locale when fallbacks are nil" do
        stub_fallbacks(nil)

        @choice_translations = {de: "", en: "", fr: "Fallback", it: ""}
        expect(choice.choice).to eql("")
      end

      it "should use default locale when fallbacks are true" do
        stub_fallbacks(true)
        I18n.default_locale = :it

        @choice_translations = {de: "", en: "", fr: "Fallback", it: "Default locale"}
        expect(choice.choice).to eql("Default locale")

        I18n.default_locale = :de
      end

      it "should use correct fallback when fallbacks are an array" do
        stub_fallbacks([:de, :fr, :it, :en])

        @choice_translations = {de: "", en: "Fallback 3", fr: "Fallback 1", it: "Fallback 2"}
        expect(choice.choice).to eql("Fallback 1")
        stub_fallbacks([:de, :it, :fr, :en])
        expect(choice.choice).to eql("Fallback 2")
        stub_fallbacks([:de, :en, :it, :fr])
        expect(choice.choice).to eql("Fallback 3")
        stub_fallbacks([:de])
        expect(choice.choice).to eql("")
      end

      it "should use correct fallback when fallbacks are a hash" do
        stub_fallbacks({de: :it, fr: [:de, :en]})

        @choice_translations = {de: "", en: "Fallback 2", fr: "", it: "Fallback 1"}

        expect(choice.choice).to eql("Fallback 1")

        I18n.locale = :fr
        expect(choice.choice).to eql("Fallback 2")
      end

      it "should return original value if fallbacks are also not present" do
        stub_fallbacks({de: :it, en: :fr})

        @choice_translations = {de: "", en: nil, fr: "", it: nil}

        expect(choice.choice).to eql("")

        I18n.locale = :en
        expect(choice.choice).to be_nil
      end

      def stub_fallbacks(fallbacks)
        allow(I18n).to receive(:fallbacks).and_return(fallbacks)
      end
    end

    describe "#checked?" do
      let(:choice1) { Choice.new({de: "Choice 1 DE", en: "Choice 1 EN", fr: "Choice 1 FR", it: "Choice 1 IT"}) }
      let(:choice2) { Choice.new({de: "Choice 2 DE", en: "Choice 2 EN", fr: "Choice 2 FR", it: "Choice 2 IT"}) }
      let(:choice3) { Choice.new({de: "Choice 3 DE", en: "Choice 3 EN", fr: "Choice 3 FR", it: "Choice 3 IT"}) }

      it "should return true for checked option if single choice is selectable" do
        answers = "Choice 1 EN"
        Globalized.languages.each do |lang|
          I18n.locale = lang
          expect(choice1.checked?(answers)).to be_truthy
          expect(choice2.checked?(answers)).to be_falsy
          expect(choice3.checked?(answers)).to be_falsy
        end
      end

      it "should return true for all checked options if multiple choices are selectable" do
        answers = "Choice 1 EN,Choice 3 EN"
        Globalized.languages.each do |lang|
          I18n.locale = lang
          expect(choice1.checked?(answers)).to be_truthy
          expect(choice2.checked?(answers)).to be_falsy
          expect(choice3.checked?(answers)).to be_truthy
        end
      end
    end
  end
end
