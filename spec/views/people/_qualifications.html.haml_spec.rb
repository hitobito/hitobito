# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe "people/_qualifications.html.haml" do
  let(:top_leader) { people(:top_leader) }
  let(:top_group) { groups(:top_group) }
  let(:sl) { qualification_kinds(:sl) }
  let(:gl) { qualification_kinds(:gl) }
  let(:dom) { @dom = Capybara::Node::Simple.new(@rendered) }

  before do
    allow(view).to receive_messages(parent: top_group, entry: top_leader.decorate, show_buttons: true)
    allow(view).to receive_messages(current_user: top_leader)
    allow(controller).to receive_messages(current_user: top_leader)
  end

  context "table order" do
    before do
      create_qualification
      create_qualification(finish_at_at: 1.year.ago, kind: gl)
      render
    end

    it "lists qualifications finish_at DESC " do
      expect(dom).to have_css("table tr", count: 2)
      expect(dom.all("tr strong").first.text).to eq "Super Lead"
      expect(dom.all("tr strong").last.text).to eq "Group Lead"
    end
  end

  context "action links" do
    let(:ql_sl) { create_qualification }

    before { ql_sl }

    it "lists delete buttons" do
      render
      expect(dom.all("tr a").first[:href]).to eq path(ql_sl)
    end

    it "has button to add new qualification" do
      render
      expect(dom.all("a").first[:href]).to eq new_group_person_qualification_path(top_group, top_leader)
    end

    def path(qualification)
      group_person_qualification_path(top_group, top_leader, qualification)
    end
  end

  def create_qualification(opts = {})
    opts = {kind: sl, finish_at: 1.year.from_now}.merge(opts)
    Fabricate(:qualification, person: top_leader, qualification_kind: opts[:kind], finish_at: opts[:finish_at].to_date)
  end
end
