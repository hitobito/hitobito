require 'spec_helper'

describe ContactableDecorator do
  before do
    group = Group.new({ id: 1, name: 'foo', address: 'foostreet 3', zip_code: '4242', town: 'footown', email: 'foo@foobar.com' })
    @group = GroupDecorator.decorate(group)
  end

  it "#complete_address" do
    @group.complete_address.should eq '<p>foostreet 3<br />4242 footown</p>'
  end
  
  it "#primary_email" do
    @group.primary_email.should eq '<p><a href="mailto:foo@foobar.com">foo@foobar.com</a> <span class="muted">Email</span></p>'
  end

  it "#all_phone_numbers" do
    pending
  end

end