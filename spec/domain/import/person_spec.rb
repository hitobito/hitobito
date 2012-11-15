require 'spec_helper'
describe Import::Person do

  context "keys" do
    subject { Import::Person.fields.map {|entry| entry[:key] }  } 
    it "contains social media" do
      should include("social_account_skype")
    end

    it "contains phone number" do
      should include("phone_number_vater")
    end
  end

  context "labels" do
    subject { Import::Person.fields.map {|entry| entry[:value] }  } 

    it "contains social media" do
      should include("Social Media Adresse Skype")
    end

    it "contains phone number" do
      should include("Telefonnummer Mutter")
    end

  end

  context "extract phone numbers" do
    let(:data) { {first_name: 'foo', social_account_skype: 'foobar', phone_number_vater: '0123' } } 
    subject { Import::Person.new(data).person } 

    its(:first_name) { should eq 'foo' }
    its('phone_numbers.first') { should be_present } 
    its('phone_numbers.first.label') { should eq 'Vater' } 
    its('phone_numbers.first.number') { should eq '0123' } 

    its('social_accounts.first') { should be_present } 
    its('social_accounts.first.label') { should eq 'Skype' } 
    its('social_accounts.first.name') { should eq 'foobar' } 
  end

end

