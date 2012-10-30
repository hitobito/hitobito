# encoding: UTF-8
require 'spec_helper'
describe "qualifications/_form.html.haml" do
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }

  before do
    qualification = person.qualifications.build
    path_args = [group, person, qualification]
    view.stub(parents: [group, person], entry: qualification, path_args: path_args)
  end
  subject { Capybara::Node::Simple.new(rendered) }
  it "translates form fields" do
    render
    should have_content "Qualifiziert für"
    should have_content "Seit"
  end
  
end

