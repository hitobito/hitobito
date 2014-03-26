# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: additional_emails
#
#  id               :integer          not null, primary key
#  contactable_id   :integer          not null
#  contactable_type :string(255)      not null
#  email            :string(255)      not null
#  label            :string(255)
#  public           :boolean          default(TRUE), not null
#  mailings         :boolean          default(TRUE), not null
#

require 'spec_helper'

describe AdditionalEmail do

  context 'validation' do
    it 'uses devise regexp for email' do
      a1 = Fabricate(:additional_email, label: 'Foo')
      a1.should be_valid

      a1.email = 'foo'
      a1.should_not be_valid
    end
  end

  context '.normalize_label' do
    it 'reuses existing label' do
      a1 = Fabricate(:additional_email, label: 'Foo')
      a2 = Fabricate(:additional_email, label: 'fOO')
      a2.label.should == 'Foo'
    end
  end

  context '#available_labels' do
    subject { AdditionalEmail.available_labels }
    it { should include(Settings.additional_email.predefined_labels.first) }

    it 'includes labels from database' do
      a = Fabricate(:additional_email, label: 'Foo')
      should include('Foo')
    end

    it 'includes labels from database and predefined only once' do
      predef = Settings.additional_email.predefined_labels.first
      a = Fabricate(:additional_email, label: predef)
      subject.count(predef).should == 1
    end
  end

  context 'paper trails', versioning: true do
    let(:person) { people(:top_leader) }

    it 'sets main on create' do
      expect do
        person.additional_emails.create!(label: 'Foo', email: 'bar@bar.com')
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      version.event.should == 'create'
      version.main.should == person
    end

    it 'sets main on update' do
      account = person.additional_emails.create(label: 'Foo', email: 'bar@bar.com')
      expect do
        account.update_attributes!(email: 'bur@bur.com')
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      version.event.should == 'update'
      version.main.should == person
    end

    it 'sets main on destroy' do
      account = person.additional_emails.create(label: 'Foo', email: 'bar@bar.com')
      expect do
        account.destroy!
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      version.event.should == 'destroy'
      version.main.should == person
    end
  end
end
