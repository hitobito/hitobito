# frozen_string_literal: true

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Dropdown::GroupAdd" do
  include FormatHelper
  include I18nHelper
  include LayoutHelper
  include UtilityHelper

  let(:group) { groups(:top_layer) }
  let(:dropdown) { Dropdown::GroupAdd.new(self, group) }

  subject { dropdown.to_s }

  def can?(*_args)
    true
  end

  it "renders dropdown" do
    is_expected.to have_content "Gruppe erstellen"
    is_expected.to have_selector "ul.dropdown-menu"
    is_expected.to have_selector "a" do |tag|
      expect(tag).to have_content "Group::TopGroup"
    end
    is_expected.to have_selector "a" do |tag|
      expect(tag).to have_content "Group::BottomLayer"
    end
  end
end
