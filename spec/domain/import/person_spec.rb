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

  context "keep existing phone numbers" do
    before do
      p = Fabricate(:person, email: 'foo@example.com')
      p.phone_numbers.create!(number: '123', label: 'Privat')
      p.phone_numbers.create!(number: '456', label: 'Mobil')
      p.social_accounts.create!(name: 'foo', label: 'Skype')
      p.social_accounts.create!(name: 'foo', label: 'MSN')
    end

    let(:data) do
       {first_name: 'foo',
        email: 'foo@example.com',
        social_account_skype: 'foo',
        social_account_msn: 'bar',
        phone_number_mobil: '123' }
    end

    subject { Import::Person.new(data).person }

    its('phone_numbers.first.label') { should eq 'Privat' }
    its('phone_numbers.first.number') { should eq '123' }
    its('phone_numbers.second.label') { should eq 'Mobil' }
    its('phone_numbers.second.number') { should eq '456' }

    its('social_accounts.first.label') { should eq 'Skype' }
    its('social_accounts.first.name') { should eq 'foo' }

    its('social_accounts.second.label') { should eq 'MSN' }
    its('social_accounts.second.name') { should eq 'foo' }

    its('social_accounts.third.label') { should eq 'Msn' }
    its('social_accounts.third.name') { should eq 'bar' }
  end


  context "can assign mass assigned attributes" do
    let(:data) { "all attributes - blacklist" }
    let(:person) { Fabricate(:person) }
    it "all protected attributes are filtered via blacklist" do
      public_attributes = person.attributes.reject { |key, value| Import::Person::BLACKLIST.include?(key.to_sym) }
      public_attributes.size.should eq 13
      expect { Import::Person.new(public_attributes).person }.not_to raise_error
    end
  end


end

