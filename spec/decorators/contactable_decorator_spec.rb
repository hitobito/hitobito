require 'spec_helper'

describe ContactableDecorator do
  before do
    group = Group.new({ id: 1, name: 'foo', address: 'foostreet 3', zip_code: '4242', town: 'footown', email: 'foo@foobar.com' })
    group.phone_numbers.new(number: '031 12345', label: 'Home', public: true)
    group.phone_numbers.new(number: '041 12345', label: 'Work', public: true)
    group.phone_numbers.new(number: '079 12345', label: 'Mobile', public: false)
    @group = GroupDecorator.decorate(group)
  end

  it "#complete_address" do
    @group.complete_address.should eq '<p>foostreet 3<br />4242 footown</p>'
  end
  
  it "#primary_email" do
    @group.primary_email.should eq '<p><a href="mailto:foo@foobar.com">foo@foobar.com</a></p>'
  end

  describe "#all_phone_numbers" do
    context "only public" do
      subject { @group.all_phone_numbers }
      
      it { should =~ /031.*Home/ }
      it { should =~ /041.*Work/ }
      it { should_not =~ /079.*Mobile/ }
    end
        
    context "all" do
      subject { @group.all_phone_numbers(false) }
      
      it { should =~ /031.*Home/ }
      it { should =~ /041.*Work/ }
      it { should =~ /079.*Mobile/ }
    end
  end

end