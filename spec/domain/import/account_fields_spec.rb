require 'spec_helper'
describe Import::AccountFields do

  subject { Import::AccountFields.new(model) } 
  context "PhoneNumber" do
    let(:model) { PhoneNumber } 
    its(:keys) { should eq Settings.phone_number.predefined_labels.collect {|l| "phone_number_#{l.downcase}" } } 
    its(:values) { should eq Settings.phone_number.predefined_labels.collect {|l| "Telefonnummer #{l}" } }

    its('fields.first') { should eq key: "phone_number_privat", value: "Telefonnummer Privat" } 
  end

  context "SocialAccount" do
    let(:model) { SocialAccount } 
    its(:keys) { should eq Settings.social_account.predefined_labels.collect {|l| "social_account_#{l.downcase}" } } 
    its(:values) { should eq Settings.social_account.predefined_labels.collect {|l| "Social Media Adresse #{l}" } }
    its('fields.first') do
       should eq({key: "social_account_#{Settings.social_account.predefined_labels.first.downcase}",
                  value: "Social Media Adresse #{Settings.social_account.predefined_labels.first}"})
    end
  end
  
end

