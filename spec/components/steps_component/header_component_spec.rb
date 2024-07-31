# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe StepsComponent::HeaderComponent, type: :component do
  let(:partial) { "partial" }
  let(:iterator) { double(:iterator, index: 1, first?: true, last?: false) }

  subject(:component) { described_class.new(header: partial, header_iteration: iterator, step: 0) }

  subject(:html) { render_inline(component) }

  it "renders list item with translated title" do
    expect(I18n).to receive(:t).with("partial_title")
      .and_return("translated title")
    expect(html).to have_css("li", text: "translated title")
  end

  context "with full partial path" do
    let(:partial) { "/foo/bar/buz/person_fields" }

    it "implements lookup across partial path" do
      expect(I18n).to receive(:t).with("person_fields_title", default: nil, scope: %w[foo bar buz])
        .and_return(nil)
      expect(I18n).to receive(:t).with("person_fields_title", default: nil, scope: %w[foo bar])
        .and_return(nil)
      expect(I18n).to receive(:t).with("person_fields_title", default: nil, scope: %w[foo])
        .and_return("translated title")
      expect(html).to have_css("li", text: "translated title")
    end
  end
end
