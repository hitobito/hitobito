require 'spec_helper'
describe GroupDecorator do

  describe "selecting attributes" do
    let(:model) { double("model")}
    let(:subject) { GroupDecorator.new(model) }
    let(:context) { double("context")}
    before do
      subject.stub(h: context)
      model.stub_chain(:class, :attr_used?) {|val| val }
    end

    it "#used_attributes selects via .attr_used?" do
      model.class.should_receive(:attr_used?).twice
      subject.used_attributes(:foo,:bar).should eq %w(foo bar)
    end

    it "#modifiable_attributes we can :modify_superior" do
      context.should_receive(:can?).with(:modify_superior, subject).and_return(true)
      subject.modifiable_attributes(:foo,:bar).should eq %w(foo bar)
    end

    it "#modifiable_attributes filters attributes if we cannot :modify_superior" do
      model.class.stub(superior_attributes: %w(foo))
      context.should_receive(:can?).with(:modify_superior, subject).and_return(false)
      subject.modifiable_attributes(:foo,:bar).should eq %w(bar)
    end
  end

end
