require 'spec_helper'
describe GroupDecorator, :draper_with_helpers do
  include Rails.application.routes.url_helpers

  let(:model) { double("model")}
  let(:decorator) { GroupDecorator.new(model) } 
  let(:context) { double("context")}
  subject { decorator }

  describe "possible roles" do
    let(:model) { groups(:top_group) } 
    its(:possible_roles) { should eq [{:sti_name=>"Group::TopGroup::Leader", :human=>"Leader"}, 
                                      {:sti_name=>"Group::TopGroup::Member", :human=>"Member"}, 
                                      {:sti_name=>"Role::External", :human=>"External"}]} 

    describe "possible_role_links" do
      subject { decorator.possible_role_links } 
      its(:size) { should eq 3 } 
      its(:first) { should eq "<a href=\"#{path(Group::TopGroup::Leader)}\">als Leader</a>" } 
      its(:second) { should eq "<a href=\"#{path(Group::TopGroup::Member)}\">als Member</a>" } 
      its(:third) { should eq "<a href=\"#{path(Role::External)}\">als External</a>" } 

      def path(type)
        new_group_role_path(model, role: {type: type})
      end
    end
  end

  describe "selecting attributes" do
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
