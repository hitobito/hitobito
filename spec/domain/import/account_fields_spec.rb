# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe Import::ContactAccountFields do

  subject { Import::ContactAccountFields.new(model) }
  context 'PhoneNumber' do
    let(:model) { PhoneNumber }
    its(:keys) { should eq Settings.phone_number.predefined_labels.collect { |l| "phone_number_#{l.downcase}" } }
    its(:values) { should eq Settings.phone_number.predefined_labels.collect { |l| "Telefonnummer #{l}" } }

    its('fields.first') { should eq key: 'phone_number_privat', value: 'Telefonnummer Privat' }
  end

  context 'SocialAccount' do
    let(:model) { SocialAccount }
    its(:keys) { should eq Settings.social_account.predefined_labels.collect { |l| "social_account_#{l.downcase}" } }
    its(:values) { should eq Settings.social_account.predefined_labels.collect { |l| "Social Media Adresse #{l}" } }
    its('fields.first') do
       should eq(key: "social_account_#{Settings.social_account.predefined_labels.first.downcase}",
                 value: "Social Media Adresse #{Settings.social_account.predefined_labels.first}")
    end
  end

  context 'AdditionalEmail' do
    let(:model) { AdditionalEmail }
    its(:keys) { should eq Settings.additional_email.predefined_labels.collect { |l| "additional_email_#{l.downcase}" } }
    its(:values) { should eq Settings.additional_email.predefined_labels.collect { |l| "Weitere E-Mail #{l}" } }
    its('fields.first') do
       should eq(key: "additional_email_#{Settings.additional_email.predefined_labels.first.downcase}",
                 value: "Weitere E-Mail #{Settings.additional_email.predefined_labels.first}")
    end
  end
end
