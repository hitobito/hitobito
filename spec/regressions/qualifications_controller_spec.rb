#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require "spec_helper"

describe QualificationsController, type: :controller do
  let(:top_group) { groups(:top_group) }
  let(:top_leader) { people(:top_leader) }

  def scope_params
    {group_id: top_group.id, person_id: top_leader.id}
  end

  # Override a few methods to match the actual behavior.
  class << self
    def it_should_redirect_to_show
      it do
        is_expected.to redirect_to group_person_path(top_group, top_leader)
      end
    end

    def it_should_redirect_to_index
      it { is_expected.to redirect_to group_person_path(top_group, top_leader) }
    end
  end

  let(:test_entry) { @entry }
  let(:test_entry_attrs) { {start_at: 1.day.from_now.to_date, qualification_kind_id: qualification_kinds(:sl).id} }

  before do
    sign_in(people(:top_leader))
    @entry = Fabricate(:qualification, person: top_leader)
  end

  include_examples "crud controller", skip: [%w[show], %w[edit], %w[index], %w[update]]

  describe_action :get, :new do
    context ".html", format: :html do
      let(:page) { Capybara::Node::Simple.new(response.body).find("#page") }

      it "renders sheets and form" do
        expect(page).to have_css(".sheet", count: 3)
        sheet = page.find(".container-fluid > .sheet.parent")
        expect(sheet.find(".breadcrumb").find_link("Top")[:href]).to eq group_path(groups(:top_layer))
        expect(sheet.find_link("TopGroup")[:href]).to eq group_people_path(top_group, returning: true)
        expect(sheet.find_link("Personen")[:href]).to eq group_people_path(top_group, returning: true)
        expect(sheet.find_link("Top Leader")[:href]).to eq group_person_path(top_group, top_leader)
        nav = page.find(".nav-left")
        expect(nav.find_link("Top")[:href]).to eq group_people_path(groups(:top_layer), returning: true)
        expect(nav.find_link("TopGroup")[:href]).to eq group_people_path(top_group, returning: true)
        expect(nav.find_link("Bottom One")[:href]).to eq group_people_path(groups(:bottom_layer_one), returning: true)
        expect(nav.find_link("Bottom Two")[:href]).to eq group_people_path(groups(:bottom_layer_two), returning: true)
      end
    end
  end
end
