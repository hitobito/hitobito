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
      subject.used_attributes(:foo,:bar).should eq [:foo, :bar]
    end

    it "#modifiable_attributes we can :modify_superior" do
      context.should_receive(:can?).with(:modify_superior, subject).and_return(true)
      subject.modifiable_attributes(:foo,:bar).should eq [:foo, :bar]
    end

    it "#modifiable_attributes filters attributes if we cannot :modify_superior" do
      model.class.stub(superior_attributes: [:foo])
      context.should_receive(:can?).with(:modify_superior, subject).and_return(false)
      subject.modifiable_attributes(:foo,:bar).should eq [:bar]
    end
  end

  describe "ContactableDecorator" do
    before do
      group = Group.new({ id: 1, name: 'foo', address: 'foostreet 3', zip_code: '4242', town: 'footown', email: 'foo@foobar.com' })
      @group = GroupDecorator.decorate(group)
    end

    it "#complete_address" do
      @group.complete_address.should eq '<address>foostreet 3<br />4242 footown</address>'
    end
    
    it "#prim_email" do
      @group.prim_email.should eq '<email><a href="mailto:foo@foobar.com">foo@foobar.com</a></email>'
    end

    # TODO write tests for all_phone_numbers, all_social_accounts
    #it "#all_phone_numbers" do
    #  @group.all_phone_numbers.should eq '...'
    #end

    it "#attr_tag should return an empty string if there is no content given" do
      @group.instance_eval{attr_tag(:foo, '')}.should eq nil
    end

  end

end
