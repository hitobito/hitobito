# == Schema Information
#
# Table name: label_formats
#
#  id               :integer          not null, primary key
#  page_size        :string           default("A4"), not null
#  landscape        :boolean          default(FALSE), not null
#  font_size        :float            default(11.0), not null
#  width            :float            not null
#  height           :float            not null
#  count_horizontal :integer          not null
#  count_vertical   :integer          not null
#  padding_top      :float            not null
#  padding_left     :float            not null
#

#  Copyright (c) 2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe LabelFormat do
  it "nullifies people last_label_format_id on destroy" do
    f = Fabricate(:label_format)
    p = Person.first
    p.update!(last_label_format: f)
    f.destroy
    expect(p.reload.last_label_format_id).to be_nil
  end

  context ".for_person" do
    let(:person) { Person.first }

    before do
      Fabricate(:label_format, person: person)
    end

    it "includes all label formats if show_global_label_formats" do
      person.show_global_label_formats = true

      expect(LabelFormat.for_person(person).size).to eq(4)
    end

    it "includes only personal label formats if !show_global_label_formats" do
      person.show_global_label_formats = false

      expect(LabelFormat.for_person(person).size).to eq(1)
    end
  end
end
