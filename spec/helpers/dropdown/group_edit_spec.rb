# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Dropdown::GroupEdit" do
  include FormatHelper
  include I18nHelper
  include LayoutHelper
  include UtilityHelper

  let(:group) { groups(:top_layer) }
  let(:dropdown) { Dropdown::GroupEdit.new(self, group) }

  subject { dropdown.to_s }

  before do
    allow(self).to receive(:can?).and_return(true)
  end

  it "renders dropdown" do
    is_expected.to have_content "Bearbeiten"
    is_expected.to have_selector "ul.dropdown-menu"
  end

  it "renders service token item with index_service_tokens" do
    allow(self).to receive(:can?).with(:index_service_tokens, anything).and_return(true)

    is_expected.to have_selector "a", text: "API-Keys"
  end

  it "does not render service token item without index_service_tokens" do
    allow(self).to receive(:can?).with(:index_service_tokens, anything).and_return(false)

    is_expected.to have_no_selector "a", text: "API-Keys"
  end

  it "renders calendar item" do
    allow(self).to receive(:can?).with(:index_service_tokens, anything).and_return(true)

    is_expected.to have_selector "a", text: "Kalender-Feeds"
  end

  it "renders merge group item" do
    is_expected.to have_selector "a", text: "Fusionieren"
  end

  it "does not render merge group item if group is archived" do
    group.archive!

    is_expected.to have_no_selector "a", text: "Fusionieren"
  end

  it "renders move group item" do
    is_expected.to have_selector "a", text: "Verschieben"
  end

  it "does not render move group item if group is archived" do
    group.archive!

    is_expected.to have_no_selector "a", text: "Verschieben"
  end

  it "renders archive group item if group is archivable" do
    allow(self).to receive(:ti).and_return("")
    allow(group).to receive(:archivable?).and_return(true)

    is_expected.to have_selector "a", text: "Archivieren"
  end

  it "does not render archive group item if group is not archivable" do
    allow(self).to receive(:ti).and_return("")
    allow(group).to receive(:archivable?).and_return(false)

    is_expected.to have_no_selector "a", text: "Archivieren"
  end

  it "renders delete group item" do
    allow(self).to receive(:ti).and_return("")
    allow(self).to receive(:can?).with(:destroy, anything).and_return(true)
    allow(group).to receive(:protected?).and_return(false)

    is_expected.to have_selector "a", text: "Löschen"
  end

  it "does not render delete group item if group is protected" do
    allow(self).to receive(:ti).and_return("")
    allow(self).to receive(:can?).with(:destroy, anything).and_return(true)
    allow(group).to receive(:protected?).and_return(true)

    is_expected.to have_no_selector "a", text: "Archivieren"
  end

  it "does not render delete group item without destroy group permission" do
    allow(self).to receive(:ti).and_return("")
    allow(self).to receive(:can?).with(:destroy, anything).and_return(false)
    allow(group).to receive(:protected?).and_return(false)

    is_expected.to have_no_selector "a", text: "Archivieren"
  end
end
