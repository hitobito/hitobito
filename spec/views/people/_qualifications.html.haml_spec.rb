require 'spec_helper'
describe 'people/_qualifications.html.haml' do

  let(:top_leader) { people(:top_leader) }
  let(:top_group) { groups(:top_group) }
  let(:sl) { qualification_kinds(:sl) }
  let(:gl) { qualification_kinds(:gl) }
  let(:dom) { @dom = Capybara::Node::Simple.new(@rendered) }

  before do
    view.stub(parent: top_group, entry: top_leader, create_button: true)
    view.stub(current_user: top_leader)
    controller.stub(current_user: top_leader)
  end
  

  context "table order" do
    before do
      assign(:qualifications,[create_qualification, create_qualification(finish_at_at: 1.year.ago, kind: gl)])
      render 
    end

    it "lists qualifications finish_at DESC " do
      dom.should have_css('table tr', count: 2)
      dom.all('tr strong').first.text.should eq 'Super Lead'
      dom.all('tr strong').last.text.should eq 'Group Lead'
    end
  end

  context "action links" do
    let(:ql_sl) { create_qualification }
    before { assign(:qualifications, [ql_sl]) }

    it "lists delete buttons" do
      render
      dom.all('tr a').first[:href].should eq path(ql_sl)
    end

    it "has button to add new qualification" do
      render
      dom.all('a').first[:href].should eq new_group_person_qualification_path(top_group, top_leader)
    end

    def path(qualification)
      group_person_qualification_path(top_group, top_leader, qualification)
    end

  end
  

  def create_qualification(opts={})
    opts = { kind: sl, finish_at: 1.year.from_now }.merge(opts)
    Fabricate(:qualification, person: top_leader, qualification_kind: opts[:kind], finish_at: opts[:finish_at].to_date)
  end
  
end

