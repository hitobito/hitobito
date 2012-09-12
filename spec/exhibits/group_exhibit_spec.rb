require 'display_case'
require 'forwardable'
require_relative '../../app/exhibits/group_exhibit.rb'

describe GroupExhibit do

  describe "custom_fields" do
    subject { GroupExhibit.custom_fields } 
    its([:federalboard]) { should eq [:bank_account] }
  end

  describe "instance" do

    before do
      @model = double("model", type: "Group::FederalBoard")
      @context = double("context")
      @form = double("form builder")
      @obj = GroupExhibit.new(@model, @context)
    end

    let(:subject) { @obj } 
    its(:type_as_sym) { should eq :federalboard } 

    it "#custom_fields adds custom_fields for foo and bar" do
      @form.should_receive(:labeled_input_field).with(:bank_account).and_return { "" }
      @obj.custom_fields(@form)
    end

  end

end
