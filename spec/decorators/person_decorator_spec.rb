require 'spec_helper'

describe PersonDecorator, :draper_with_helpers do
  include Rails.application.routes.url_helpers
  
  let(:person) { people(:top_leader) }
  
  subject { PersonDecorator.new(person) }
  
  
  its(:full_label)   { should == "Top Leader, Supertown" }
  its(:address_name) { should == '<strong>Top Leader</strong>' }
  
  context "with town and birthday" do
    let(:person) { Fabricate(:person, first_name: 'Fra', 
                                      last_name: 'Stuck', 
                                      nickname: 'Schu',
                                      company_name: 'Coorp',
                                      birthday: '3.8.76', 
                                      town: 'City') }
                                      
    its(:full_label)     { should == "Fra Stuck / Schu, City (1976)"}
    its(:address_name)   { should == "Coorp<br /><strong>Fra Stuck / Schu</strong>" }
    its(:additional_name) { should == 'Coorp' }
  end
  
  context "as company" do
    let(:person) { Fabricate(:person, first_name: 'Fra', 
                                      last_name: 'Stuck',
                                      nickname: 'Schu',
                                      company_name: 'Coorp',
                                      birthday: '3.8.76', 
                                      town: 'City',
                                      company: true) }
                                      
    its(:full_label)      { should == "Coorp, City (Fra Stuck)"}
    its(:address_name)    { should == "<strong>Coorp</strong><br />Fra Stuck" }
    its(:additional_name) { should == 'Fra Stuck' }
  end
  
end
