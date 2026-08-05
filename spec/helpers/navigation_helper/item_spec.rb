# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe NavigationHelper::Item do
  let(:view) { double("view") }

  describe "#initialize" do
    it "requires a :path" do
      expect { described_class.new(model: LabelFormat) }.to raise_error(KeyError)
    end
  end

  describe "#visible?" do
    context "with an :if condition" do
      subject(:item) do
        described_class.new(path: :imap_mails_path, if: ->(_) { can?(:manage, Imap::Mail) })
      end

      it "is visible when the condition evaluates to true in the view's context" do
        allow(view).to receive(:can?).with(:manage, Imap::Mail).and_return(true)
        expect(item.visible?(view)).to eq(true)
      end

      it "is hidden when the condition evaluates to false" do
        allow(view).to receive(:can?).with(:manage, Imap::Mail).and_return(false)
        expect(item.visible?(view)).to eq(false)
      end
    end

    context "with a :model and no :if" do
      subject(:item) { described_class.new(model: LabelFormat, path: :label_formats_path) }

      it "defaults to can?(:index, model)" do
        allow(view).to receive(:can?).with(:index, LabelFormat).and_return(true)
        expect(item.visible?(view)).to eq(true)
      end

      it "is hidden when can?(:index, model) is false" do
        allow(view).to receive(:can?).with(:index, LabelFormat).and_return(false)
        expect(item.visible?(view)).to eq(false)
      end
    end

    context "with neither :if nor :model" do
      subject(:item) { described_class.new(label: "json_api", path: :api_path) }

      it "is always visible" do
        expect(item.visible?(view)).to eq(true)
      end
    end
  end

  describe "#label" do
    it "translates the :label key when given" do
      allow(view).to receive(:t).with("json_api").and_return("JSON API")
      item = described_class.new(label: "json_api", path: :api_path)

      expect(item.label(view)).to eq("JSON API")
    end

    it "falls back to the model's human name when no :label is given" do
      item = described_class.new(model: LabelFormat, path: :label_formats_path)
      expect(item.label(view)).to eq(LabelFormat.model_name.human(count: 2))
    end
  end

  describe "#url" do
    it "sends a symbol :path to the view" do
      allow(view).to receive(:label_formats_path).and_return("/label_formats")
      item = described_class.new(model: LabelFormat, path: :label_formats_path)

      expect(item.url(view)).to eq("/label_formats")
    end

    it "evaluates a proc :path in the view's context" do
      allow(view).to receive(:imap_mails_path)
        .with(mailbox: "inbox").and_return("/mails/imap/inbox")
      item = described_class.new(path: ->(_) { imap_mails_path(mailbox: "inbox") })

      expect(item.url(view)).to eq("/mails/imap/inbox")
    end
  end

  describe "#active_for" do
    it "uses the explicit :active_for override when given" do
      item = described_class.new(path: :imap_mails_path, active_for: "mails/imap")
      expect(item.active_for(view)).to eq("mails/imap")
    end

    it "derives the fragment from the url otherwise" do
      allow(view).to receive(:label_formats_path).and_return("/de/label_formats")
      item = described_class.new(model: LabelFormat, path: :label_formats_path)

      expect(item.active_for(view)).to eq("de/label_formats")
    end

    it "strips a query string from a derived url" do
      allow(view).to receive(:api_path).and_return("/api?locale=de")
      item = described_class.new(label: "json_api", path: :api_path)

      expect(item.active_for(view)).to eq("api")
    end
  end

  describe "#current?" do
    it "delegates to the view's section_active? with the item's url and active_for" do
      allow(view).to receive(:label_formats_path).and_return("/label_formats")
      item = described_class.new(model: LabelFormat, path: :label_formats_path)

      expect(view).to receive(:section_active?)
        .with("/label_formats", ["label_formats"]).and_return(true)

      expect(item.current?(view)).to eq(true)
    end
  end
end
