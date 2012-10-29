require 'spec_helper'
describe 'people/_qualifications.html.haml' do

  let(:top_leader) { people(:top_leader) }
  let(:top_group) { groups(:top_group) }
  let(:sl) { qualification_kinds(:sl) }
  let(:gl) { qualification_kinds(:gl) }
  let(:dom) { @dom = Capybara::Node::Simple.new(@rendered) }

  before do
    ql_sl = create_qualification
    ql_gl = create_qualification finish_at_at: 1.year.ago, kind: gl
    view.stub(parent: top_group, title: 'Qualifikationen', collection: [ql_sl, ql_gl])
    render 
  end

  it "lists qualifications in table" do
    dom.should have_css('table tr', count: 2)
    dom.all('tr strong').first.text.should eq 'Super Lead'
    dom.all('tr strong').last.text.should eq 'Group Lead'
  end

  def create_qualification(opts={})
    opts = { kind: sl, finish_at: 1.year.from_now }.merge(opts)
    Fabricate(:qualification, qualification_kind: opts[:kind], finish_at: opts[:finish_at])
  end
  
end

