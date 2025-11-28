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
  end
end
