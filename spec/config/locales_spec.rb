# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require "spec_helper"

describe "locales" do
  context "fallbacks" do
    let(:translations) do
      {
        de: {hello_test: "Hallo"},
        fr: {hello_test: "Bonjour"},
        it: {hello_test: "Ciao"},
        en: {hello_test: "Hello"},
      }
    end

    def t(locale) = translations.dig(locale, :hello_test)

    it "de falls back to fr, it, en, original" do
      with_translations(translations.except(:de)) do
        expect(I18n.t(:hello_test, locale: :de)).to eq t(:fr)
      end

      with_translations(translations.except(:de, :fr)) do
        expect(I18n.t(:hello_test, locale: :de)).to eq t(:it)
      end

      with_translations(translations.except(:de, :fr, :it)) do
        expect(I18n.t(:hello_test, locale: :de)).to eq t(:en)
      end
    end

    it "fr falls back to it, en, de, original" do
      with_translations(translations.except(:fr)) do
        expect(I18n.t(:hello_test, locale: :fr)).to eq t(:it)
      end

      with_translations(translations.except(:fr, :it)) do
        expect(I18n.t(:hello_test, locale: :fr)).to eq t(:en)
      end

      with_translations(translations.except(:fr, :it, :en)) do
        expect(I18n.t(:hello_test, locale: :fr)).to eq t(:de)
      end
    end

    it "it falls back to fr, en, de, original" do
      with_translations(translations.except(:it)) do
        expect(I18n.t(:hello_test, locale: :it)).to eq t(:fr)
      end

      with_translations(translations.except(:it, :fr)) do
        expect(I18n.t(:hello_test, locale: :it)).to eq t(:en)
      end

      with_translations(translations.except(:it, :fr, :en)) do
        expect(I18n.t(:hello_test, locale: :it)).to eq t(:de)
      end
    end

    it "en falls back to de, fr, it, original" do
      with_translations(translations.except(:en)) do
        expect(I18n.t(:hello_test, locale: :en)).to eq t(:de)
      end

      with_translations(translations.except(:en, :de)) do
        expect(I18n.t(:hello_test, locale: :en)).to eq t(:fr)
      end

      with_translations(translations.except(:en, :de, :fr)) do
        expect(I18n.t(:hello_test, locale: :en)).to eq t(:it)
      end
    end
  end

  context 'do not contain wrong spellings of "E-Mail":' do
    it "Email" do
      expect(`grep 'Email' config/locales/*.de.yml | wc -l`.chomp.to_i).to be_zero
    end

    it "e-mail" do
      expect(`grep 'e-mail' config/locales/*.de.yml | wc -l`.chomp.to_i).to be_zero
    end

    it "e-Mail" do
      expect(`grep 'e-Mail' config/locales/*.de.yml | wc -l`.chomp.to_i).to be_zero
    end

    it "email" do
      # the spelling "email" has a few false positives :-)
      email_lines = `grep -e ':.*email' config/locales/*.de.yml`
        .split("\n").map(&:chomp)
        .reject { |line| line =~ /.*Scope: email.*/ }
        .reject { |line| line =~ /.*%{email}.*/ }

      expect(email_lines).to be_empty
    end
  end

  context 'do not contain wrong spellings of "Adresss":' do
    it "Address" do
      expect(`grep Address config/locales/*.de.yml | wc -l`.chomp.to_i).to be_zero
    end
  end
end
