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

  describe "new event links" do
    let(:context) { double("context") }
    let(:model) { double("model") }

    before do
      context.stub(can?: true)
      context.stub_chain(:new_group_event_path, :link_to, :action_button, :dropdown_button)
    end

    it "should only create link for one possible event type" do
      group = GroupDecorator.new(groups(:bottom_group_one_one))
      group.stub(h: context)
      group.should_receive(:new_event_button)
      group.new_event_dropdown_button
    end

    it "should create link dropdown for multiple possible event types" do
      group = GroupDecorator.new(groups(:top_group))
      group.stub(h: context)
      group.should_receive(:new_event_dropdown)
      group.new_event_dropdown_button
    end

  end

end
