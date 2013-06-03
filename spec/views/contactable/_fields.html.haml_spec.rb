require 'spec_helper'
describe 'contactable/_fields.html.haml' do

  let(:group) { groups(:top_layer) }
  let(:current_user) { people(:top_leader) }
  let(:form_builder) { StandardFormBuilder.new(:group, group, view, {}, nil) }

  subject { Capybara::Node::Simple.new(@rendered).find('fieldset.info', visible: false) }

  before do
    view.extend StandardHelper
    view.stub(entry: GroupDecorator.decorate(group), f: form_builder)
  end

  context "standard" do
    before { render }

    its([:style]) { should be_blank }
  end


  context "when contact is set" do
    before do
      group.contact = current_user
      render
    end

    its([:style]) { should eq 'display: none' }
  end
end

