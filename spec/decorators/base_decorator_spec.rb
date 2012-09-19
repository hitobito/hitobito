require 'spec_helper'

describe BaseDecorator do

  class Foo; end
  class Bar < Foo; end

  it ""  do
    dec = BaseDecorator.new(Bar.new)
    dec.class.model_class.should eq Bar
  end
end
