require_relative '../../app/exhibits/base_exhibit.rb'
require_relative '../../app/exhibits/group_exhibit.rb'

describe GroupExhibit do

  let(:context) { double("context")}
  let(:model) { double("model")}
  let(:subject) { GroupExhibit.new(model, context) }


  describe "selecting attributes" do
    before { subject.class.stub(:attr_used?) {|val| val } } 

    it "#used_attributes selects via .attr_used?" do
      subject.class.should_receive(:attr_used?).twice
      subject.used_attributes(:foo,:bar).should eq [:foo, :bar]
    end

    it "#modifiable_attributes we can :modify_superior" do
      context.should_receive(:can?).with(:modify_superior, subject).and_return(true)
      subject.modifiable_attributes(:foo,:bar).should eq [:foo, :bar]
    end

    it "#modifiable_attributes filters attributes if we cannot :modify_superior" do
      subject.class.stub(superior_attributes: [:foo])
      context.should_receive(:can?).with(:modify_superior, subject).and_return(false)
      subject.modifiable_attributes(:foo,:bar).should eq [:bar]
    end
  end

end
