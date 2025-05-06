# frozen_string_literal: true

#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito_cevi and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe LocaleSetter do
  let(:person) { people(:top_leader) }

  it "sets locale when locale is passed" do
    subject.with_locale(locale: :fr) do
      expect(I18n.locale).to eq(:fr)
    end
  end

  it "sets locale to person correspondence_language when correspondence_language is a thing" do
    allow(person).to receive(:respond_to?).and_return(true)
    allow(person).to receive(:correspondence_language).and_return("fr")
    subject.with_locale(person: person) do
      expect(I18n.locale).to eq(:fr)
    end
  end

  it "sets locale to person language when person with language is passed" do
    person.update!(language: :it)
    subject.with_locale(person: person) do
      expect(I18n.locale).to eq(:it)
    end
  end

  it "sets locale to previous locale when neither person or locale is passed" do
    I18n.locale = :it
    subject.with_locale do
      expect(I18n.locale).to eq(:it)
    end
  end

  it "does not set locale to locale that doesnt exist in current system" do
    I18n.available_locales -= [:en]
    person.update!(language: :en)
    subject.with_locale(locale: :en) do
      expect(I18n.locale).to eq(:de)
    end
  end

  it "ensures to reset locale back to previous locale" do
    I18n.locale = :it
    expect {
      subject.with_locale(person: person) do
        expect(I18n.locale).to eq(:de)
        raise "random error"
      end
    }.to raise_error
    expect(I18n.locale).to eq(:it)
  end
end
