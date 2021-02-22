#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe LabelFormatsController do
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }

  describe "with admin permissions" do
    before do
      sign_in(person)
    end

    it "create global label" do
      expect {
        post :create, params: {
          global: "true",
          label_format: {name: "foo layer",
                         page_size: "A4",
                         landscape: false,
                         font_size: 12,
                         width: 60, height: 30,
                         count_horizontal: 3,
                         count_vertical: 8,
                         padding_top: 5,
                         padding_left: 5,},
        }
      }.to change { LabelFormat.count }.by(1)

      expect(LabelFormat.last.person_id).to eq(nil)
    end

    it "create personal label" do
      expect {
        post :create, params: {
          global: "false",
          label_format: {name: "foo layer",
                         page_size: "A4",
                         landscape: false,
                         font_size: 12,
                         width: 60, height: 30,
                         count_horizontal: 3,
                         count_vertical: 8,
                         padding_top: 5,
                         padding_left: 5,},
        }
      }.to change { LabelFormat.count }.by(1)

      expect(LabelFormat.last.person_id).to eq(person.id)
    end
  end

  describe "without admin permissions" do
    let(:person) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person }

    before do
      sign_in(person)
    end

    it "create personal label" do
      expect {
        post :create, params: {
          global: "false",
          label_format: {name: "foo layer",
                         page_size: "A4",
                         landscape: false,
                         font_size: 12,
                         width: 60, height: 30,
                         count_horizontal: 3,
                         count_vertical: 8,
                         padding_top: 5,
                         padding_left: 5,},
        }
      }.to change { LabelFormat.count }.by(1)

      expect(LabelFormat.last.person_id).to eq(person.id)
    end

    it "can not create global label" do
      expect {
        post :create, params: {
          global: "true",
          label_format: {name: "foo layer",
                         page_size: "A4",
                         landscape: false,
                         font_size: 12,
                         width: 60, height: 30,
                         count_horizontal: 3,
                         count_vertical: 8,
                         padding_top: 5,
                         padding_left: 5,},
        }
      }.to change { LabelFormat.count }.by(1)

      expect(LabelFormat.last.person_id).to eq(person.id)
    end

    it "sorts global formats" do
      get :index, params: {sort: "dimensions", sort_dir: "desc"}

      expect(assigns(:global_entries)).to eq(label_formats(:standard, :large, :envelope))
    end
  end
end
