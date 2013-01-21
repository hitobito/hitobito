require 'spec_helper'

describe AddressHelper do
  
  it "doesn't print ch, schweiz" do
    print_country?('schweiz').should be_false
    print_country?('ch').should be_false
  end

  it "prints other countries" do
    print_country?('the ultimate country').should be_true
  end
  
end
