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

  describe "Import::Person::DoubletteFinder" do
    subject { Import::Person::DoubletteFinder.new(attrs) }

    context "empty attrs" do
      let(:attrs) { {} } 
      its(:query) { should be_blank }
      its(:find_and_update) { should be_nil } 
    end

    context "firstname only" do
      before { Person.create(attrs)  } 
      let(:attrs) { { first_name: 'foo' } }
      its(:query) { should eq 'first_name="foo"' }
      its('find_and_update.first_name') { should eq 'foo' } 
    end

    context "email only" do
      before { Person.create(attrs.merge({first_name: 'foo'})) }
      let(:attrs) { { email: 'foo@bar.com' } }
      its(:query) { should eq 'email="foo@bar.com"' }
      its('find_and_update.first_name') { should eq 'foo' } 
    end
    
    context "joins with or clause, updates first_name" do
      before { Person.create(attrs.merge(first_name: 'foo')) }
      let(:attrs) { { email: 'foo@bar.com', first_name: 'bla' } }
      its(:query) { should eq 'first_name="bla" OR email="foo@bar.com"' }
      its('find_and_update.first_name') { should eq 'bla' } 
    end  

    context "joins others with and" do
      before { Person.create(attrs) }
      let(:attrs) { { last_name: 'bar', first_name: 'foo', zip_code: '213', birthday: '1991-05-06' } }
      its(:query) { should eq 'last_name="bar" AND first_name="foo" AND zip_code="213" AND birthday="1991-05-06"' }
      its(:find_and_update) { should be_present } 
    end
  end

end

