#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Sheet::Contactables::Invoice do
  let(:view_context) { controller.view_context }

  context "people" do
    before do
      allow(view_context).to receive(:parent).and_return(people(:top_leader))
    end

    it "#parent_sheet_class does return Sheet::Person" do
      expect(described_class.parent_sheet_class(view_context)).to eq Sheet::Person
    end
  end

  context "groups" do
    before do
      allow(view_context).to receive(:parent).and_return(groups(:top_layer))
    end

    it "#parent_sheet_class does return Sheet::Group" do
      expect(described_class.parent_sheet_class(view_context)).to eq Sheet::Group
    end
  end
end
