# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "ActionText::ContentHelper::AutoLink" do
  def render(html)
    Capybara.string(ActionText::Content.new(html).to_s)
  end

  it "links urls and email addresses" do
    rendered = render("<div>Infos auf https://example.com/kurs?a=1&amp;b=2 oder info@example.com</div>")

    expect(rendered).to have_link("https://example.com/kurs?a=1&b=2",
      href: "https://example.com/kurs?a=1&b=2")
    expect(rendered).to have_link("info@example.com", href: "mailto:info@example.com")
  end

  context "with already linked urls" do
    it "does not link the url text of a link again" do
      rendered = render('<div><a href="https://example.com">https://example.com</a></div>')

      expect(rendered).to have_css("a", count: 1)
      expect(rendered).to have_link("https://example.com", href: "https://example.com")
    end

    it "does not link a url within the text of a link" do
      rendered = render('<div><a href="https://example.com">Siehe https://example.org</a></div>')

      expect(rendered).to have_css("a", count: 1)
      expect(rendered).to have_link("Siehe https://example.org", href: "https://example.com")
    end

    it "does not link a url within formatted link text" do
      rendered = render('<div><a href="https://example.com"><strong>https://example.com</strong></a></div>')

      expect(rendered).to have_css("a", count: 1)
      expect(rendered).to have_css("a strong", text: "https://example.com")
    end

    it "does not link a linked email address again" do
      rendered = render('<div><a href="mailto:info@example.com">info@example.com</a></div>')

      expect(rendered).to have_css("a", count: 1)
      expect(rendered).to have_link("info@example.com", href: "mailto:info@example.com")
    end

    it "links only the unlinked url next to a link" do
      rendered = render('<div><a href="https://example.com">https://example.com</a> und https://example.org</div>')

      expect(rendered).to have_css("a", count: 2)
      expect(rendered).to have_link("https://example.com", href: "https://example.com")
      expect(rendered).to have_link("https://example.org", href: "https://example.org")
    end

    it "does not link rendered content again" do
      rendered = render(ActionText::Content.new("<div>https://example.com</div>").to_s)

      expect(rendered).to have_css("a", count: 1)
      expect(rendered).to have_link("https://example.com", href: "https://example.com")
    end
  end

  it "sanitizes the linked content" do
    rendered = render("<div>http://example.com/&quot;onmouseover=&quot;alert(1)</div>")

    expect(rendered).to have_link("http://example.com/", href: "http://example.com/")
    expect(rendered).not_to have_css("a[onmouseover]")
  end
end

describe ActionText::RichText do
  def build(body)
    ActionText::RichText.new(record: events(:top_event).translation, name: "description", body:)
  end

  it "stores the plain text of the body" do
    rich_text = build("<div>Erste <strong>Zeile</strong><br>Zweite Zeile</div>").tap(&:save!)

    expect(rich_text.reload.plain_text_body).to eq "Erste Zeile\nZweite Zeile"
  end

  it "stores no plain text for a blank body" do
    rich_text = build("<div> </div>").tap(&:save!)

    expect(rich_text.reload.plain_text_body).to be_nil
  end

  it "stores the event name as item_label of its versions", versioning: true do
    rich_text = build("<div>x</div>").tap(&:save!)

    expect(rich_text.versions.last.item_label).to eq "Top Event"
  end

  it "saves without the plain_text_body column" do
    rich_text = build("<div>x</div>")
    allow(rich_text).to receive(:respond_to?).and_call_original
    allow(rich_text).to receive(:respond_to?).with(:plain_text_body=).and_return(false)
    expect(rich_text).not_to receive(:plain_text_body=)

    rich_text.save!
  end
end
