#  Copyright (c) 2012-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Sheet::Group::NavLeft" do
  let(:group) { groups(:bottom_group_one_one) }
  let(:sheet) { Sheet::Group.new(self, nil, group) }
  let(:nav) { Sheet::Group::NavLeft.new(sheet) }

  let(:request) { ActionController::TestRequest.create({}) }

  let(:html) { nav.render }

  subject { Capybara::Node::Simple.new(html) }

  def can?(*_args)
    true
  end

  it { is_expected.to have_selector("li", count: 4) }

  it { is_expected.to have_selector("ul", count: 2) }

  it "has balanced li tags" do
    expect(html.scan(/<li/).size).to eq html.scan(/<\/li>/).size
  end

  it "has balanced li tags if last group is stacked" do
    Fabricate(Group::BottomGroup.sti_name.to_sym, parent: groups(:bottom_group_one_two))
    expect(html.scan(/<li/).size).to eq html.scan(/<\/li>/).size
  end

  context "short name" do
    let(:group) { groups(:top_layer) }

    before do
      group.update(short_name: "TP")
      groups(:top_group).update(short_name: "TG")
    end

    it "displays header group with full name" do
      is_expected.to have_link("Top", text: "Top")
      is_expected.to_not have_link("TP", text: "TP")
    end

    # TODO: safe_join of this test's view does not behave as it should
    # it 'displays sub layer with short name if available' do
    #   is_expected.to have_link('One', text: 'One')
    #   is_expected.to_not have_link('Bottom One', text: 'Bottom One')
    # end

    it "displays group with short name if available" do
      is_expected.to have_link("TG", text: "TG")
      is_expected.to_not have_link("TopGroup", text: "TopGroup")
    end
  end

  context "layer groups visibility" do
    before do
      # Hierarchy:
      #  * Bottom One (layer)
      #    * Group 11
      #      * Group 111
      #        * Group 1111
      #      * Group 112
      #    * Group 12
      #      * Group 121

      Fabricate(Group::BottomGroup.sti_name.to_sym, parent: groups(:bottom_group_one_one_one),
                                                    name: "Group 1111")
      Fabricate(Group::BottomGroup.sti_name.to_sym, parent: groups(:bottom_group_one_one),
                                                    name: "Group 112")
      Fabricate(Group::BottomGroup.sti_name.to_sym, parent: groups(:bottom_group_one_two),
                                                    name: "Group 121")
    end

    context "Bottom One" do
      let(:group) { groups(:bottom_layer_one) }

      it "displays itself" do
        is_expected.to have_link("Bottom One")
      end

      it "displays childs" do
        is_expected.to have_link("Group 11")
        is_expected.to have_link("Group 12")
      end

      it "hides other decendents" do
        is_expected.not_to have_link("Group 111")
        is_expected.not_to have_link("Group 1111")
        is_expected.not_to have_link("Group 112")
        is_expected.not_to have_link("Group 121")
      end

      it "displays deleted peoples" do
        is_expected.to have_link(t("groups.global.link.deleted_person"))
      end
    end

    context "Group 11" do
      let(:group) { groups(:bottom_group_one_one) }

      it "displays itself" do
        is_expected.to have_link("Group 11")
      end

      it "displays childs" do
        is_expected.to have_link("Group 111")
        is_expected.to have_link("Group 112")
      end

      it "hides other decendents" do
        is_expected.not_to have_link("Group 1111")
      end

      it "displays ancestors and its siblings" do
        is_expected.to have_link("Group 12")
      end

      it "hides decendents of ancestor siblings" do
        is_expected.not_to have_link("Group 121")
      end

      it "displays deleted peoples" do
        is_expected.to have_link(t("groups.global.link.deleted_person"))
      end
    end

    context "Group 111" do
      let(:group) { groups(:bottom_group_one_one_one) }

      it "displays itself" do
        is_expected.to have_link("Group 111")
      end

      it "displays childs" do
        is_expected.to have_link("Group 1111")
      end

      it "displays ancestors and its siblings" do
        is_expected.to have_link("Group 11")
        is_expected.to have_link("Group 112")
        is_expected.to have_link("Group 12")
      end

      it "hides decendents of ancestor siblings" do
        is_expected.not_to have_link("Group 121")
      end

      it "displays deleted peoples" do
        is_expected.to have_link(t("groups.global.link.deleted_person"))
      end
    end

    context "Group 1111" do
      let(:group) { groups(:bottom_group_one_one_one) }

      it "displays ancestors and its siblings" do
        is_expected.to have_link("Group 11")
        is_expected.to have_link("Group 111")
        is_expected.to have_link("Group 112")
        is_expected.to have_link("Group 12")
      end

      it "hides decendents of ancestor siblings" do
        is_expected.not_to have_link("Group 121")
      end

      it "displays deleted peoples" do
        is_expected.to have_link(t("groups.global.link.deleted_person"))
      end
    end
  end
end
