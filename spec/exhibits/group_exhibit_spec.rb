require 'display_case'
require 'forwardable'
require_relative '../../app/exhibits/group_exhibit.rb'

describe GroupExhibit do


  let(:context) { double("context")}
  let(:subject) { GroupExhibit.new(model, context) }


  describe "#attributes" do
    def model_stub(name)
      stub("model_#{name}", model_name: name)
    end
    let(:model) { double("model", class: stub(possible_children: [model_stub(:foo), model_stub(:bar)])) }
    it "calls options_from_collection_for_select" do
      context.should_receive(:options_from_collection_for_select).with([:foo, :bar], :to_s, :human)
      subject.possible_children_options
    end
  end
end
