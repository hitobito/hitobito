require 'spec_helper'

describe ApplicationDecorator do
  it "#klass returns model class"  do
    dec = GroupDecorator.new(Group.new)
    dec.klass.should eq Group
  end
end
