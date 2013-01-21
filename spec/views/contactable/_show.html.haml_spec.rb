require 'spec_helper'
describe 'contactable/_show.html.haml' do

  let(:group) { groups(:top_layer) }
  let(:current_user) { people(:top_leader) }
  subject { Capybara::Node::Simple.new(@rendered)}

  before do
    group.assign_attributes(address: 'foo', town: 'bar', zip_code: 123, country: 'ch')
    view.stub(contactable: GroupDecorator.decorate(group), only_public: false)
  end

  context "group" do
    before { render }

    it "displays group info" do
      should have_content('foo')
      should have_content('bar')
      should have_content('123')
      should_not have_content('ch')
    end
  end

  context "group.contact" do
    before do
      current_user.assign_attributes(address: 'asdf', town: 'fdas', zip_code: 321, country: 'at')
      group.contact = current_user
      group.save
      render
    end

    it "displays contact info" do
      should have_content('asdf')
      should have_content('fdas')
      should have_content('321')
      should have_content('at')
    end
  end

end

