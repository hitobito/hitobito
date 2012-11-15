require 'spec_helper'
describe Import::SettingsFields do

  subject { Import::SettingsFields.new(model) } 
  context "PhoneNumber" do
    let(:model) { PhoneNumber } 
    its(:keys) { should eq ["phone_number_privat", "phone_number_mobil", "phone_number_arbeit", 
                            "phone_number_vater", "phone_number_mutter", "phone_number_fax", "phone_number_andere"] }
    its(:values) { should eq ["Telefonnummer Privat", "Telefonnummer Mobil", "Telefonnummer Arbeit", 
                              "Telefonnummer Vater", "Telefonnummer Mutter", "Telefonnummer Fax", "Telefonnummer Andere"] } 

    its('fields.first') { should eq key: "phone_number_privat", value: "Telefonnummer Privat" } 
  end

  context "SocialAccount" do
    let(:model) { SocialAccount } 
    its(:keys) { should eq ["social_account_skype", "social_account_webseite", "social_account_msn"] } 
    its(:values) { should eq ["Social Media Adresse Skype", "Social Media Adresse Webseite", "Social Media Adresse MSN"] }
    its('fields.first') { should eq key: "social_account_skype", value: "Social Media Adresse Skype" }
  end
  
  
end

