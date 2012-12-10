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

  describe "Import::Person::DoubletteFinder" do
    subject { Import::Person::DoubletteFinder.new(attrs) }

    context "empty attrs" do
      let(:attrs) { {} } 
      its(:query) { should eq [''] }
      its(:find_and_update) { should be_nil } 
    end

    context "firstname only" do
      before { Person.create(attrs)  } 
      let(:attrs) { { first_name: 'foo' } }
      its(:query) { should eq ['first_name = ?', 'foo'] }
      its('find_and_update.first_name') { should eq 'foo' } 
    end

    context "email only" do
      before { Person.create(attrs.merge({first_name: 'foo'})) }
      let(:attrs) { { email: 'foo@bar.com' } }
      its(:query) { should eq ['email = ?',"foo@bar.com"] }
      its('find_and_update.first_name') { should eq 'foo' } 
    end
    
    context "joins with or clause, does not change first_name, adds nickname" do
      before { Person.create(attrs.merge(first_name: 'foo', nickname: 'foobar')) }
      let(:attrs) { { email: 'foo@bar.com', first_name: 'bla' } }
      its(:query) { should eq ['(first_name = ?) OR email = ?', 'bla', 'foo@bar.com'] } 
      its('find_and_update.first_name') { should eq 'bla' } 
      its('find_and_update.nickname') { should eq 'foobar' } 
    end  

    context "joins others with and" do
      before { Person.create(attrs) }
      let(:attrs) { { last_name: 'bar', first_name: 'foo', zip_code: '213', birthday: '1991-05-06' } }
      its(:query) { should eq ['last_name = ? AND first_name = ? AND zip_code = ? AND birthday = ?', 
                               'bar', 'foo', '213', Time.zone.parse('1991-05-06').to_date] }
      its(:find_and_update) { should be_present } 
    end

  end

end

