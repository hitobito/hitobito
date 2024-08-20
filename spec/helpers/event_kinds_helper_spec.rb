#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe EventKindsHelper do
  context "qualification kinds" do
    let(:old) { qualification_kinds(:old) }
    let(:entry) { event_kinds(:glk) }
    let(:form) { StandardFormBuilder.new(:event_kind, event_kinds(:glk), view, {}) }
    let(:collection) { QualificationKind.without_deleted.list }

    before do
      allow(helper).to receive(:t).with(any_args) { "foo" }
      allow(helper).to receive(:entry) { entry }
      view.extend(FormHelper,
        TableHelper,
        UtilityHelper,
        I18nHelper,
        FormatHelper,
        LayoutHelper,
        SheetHelper,
        PeopleHelper,
        EventParticipationsHelper,
        TableDisplaysHelper,
        EventKindsHelper,
        ActionHelper,
        InvoicesHelper,
        ContactableHelper)
    end

    it "does not include deleted qualifications if not selected" do
      entry.event_kind_qualification_kinds.create!(qualification_kind_id: collection.first.id,
        role: "participant",
        category: "qualification")
      entry.event_kind_qualification_kinds.create!(qualification_kind_id: collection.second.id,
        role: "participant",
        category: "prolongation")

      html = helper.labeled_qualification_kinds_field(form, collection,
        "qualification", "participant",
        Event::Kind.human_attribute_name(:qualification_kinds))
      node = Capybara::Node::Simple.new(html)

      options = node.find("select").all("option")
      expect(options.size).to eq(collection.size)
      expect(options.select { |o| o.selected? }.size).to eq(1)
      expect(options.one? { |o| o.value == old.id.to_s }).to eq false
    end

    it "includes deleted qualifications if selected" do
      entry.event_kind_qualification_kinds.create!(qualification_kind_id: old.id,
        role: "participant",
        category: "qualification")
      entry.event_kind_qualification_kinds.create!(qualification_kind_id: collection.first.id,
        role: "participant",
        category: "qualification")
      entry.event_kind_qualification_kinds.create!(qualification_kind_id: collection.second.id,
        role: "participant",
        category: "prolongation")

      html = helper.labeled_qualification_kinds_field(form, collection,
        "qualification", "participant",
        Event::Kind.human_attribute_name(:qualification_kinds))
      node = Capybara::Node::Simple.new(html)

      options = node.find("select").all("option")
      expect(options.size).to eq(collection.size + 1)
      expect(options.select { |o| o.selected? }.size).to eq(2)
      expect(options.one? { |o| o.value == old.id.to_s }).to eq true
    end
  end
end
