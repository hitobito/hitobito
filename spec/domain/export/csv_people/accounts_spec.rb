require 'spec_helper'


describe "Export::CsvPeople::Accounts" do
  
  subject { Export::CsvPeople::Accounts }

  context "phone_numbers" do
    it "creates standard key and human translations" do
      subject.phone_numbers.key('foo').should eq :phone_number_foo
      subject.phone_numbers.human('foo').should eq 'Telefonnummer Foo'
    end
  end

  context "social_accounts" do
    it "creates standard key and human translations" do
      subject.social_accounts.key('foo').should eq :social_account_foo
      subject.social_accounts.human('foo').should eq 'Foo'
    end
  end
end
