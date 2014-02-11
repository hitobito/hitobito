# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: social_accounts
#
#  id               :integer          not null, primary key
#  contactable_id   :integer          not null
#  contactable_type :string(255)      not null
#  name             :string(255)      not null
#  label            :string(255)
#  public           :boolean          default(TRUE), not null
#

require 'spec_helper'

describe SocialAccount do

  describe '.normalize_label' do

    it 'reuses existing label' do
      a1 = Fabricate(:social_account, label: 'Foo')
      a2 = Fabricate(:social_account, label: 'fOO')
      a2.label.should == 'Foo'
    end
  end

  describe '#available_labels' do
    subject { SocialAccount.available_labels }
    it { should include(Settings.social_account.predefined_labels.first) }

    it 'includes labels from database' do
      a = Fabricate(:social_account, label: 'Foo')
      should include('Foo')
    end

    it 'includes labels from database and predefined only once' do
      predef = Settings.social_account.predefined_labels.first
      a = Fabricate(:social_account, label: predef)
      subject.count(predef).should == 1
    end
  end

  describe 'paper trails', versioning: true do
    let(:person) { people(:top_leader) }

    it 'sets main on create' do
      expect do
        person.social_accounts.create!(label: 'Foo', name: 'Bar')
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at).last
      version.event.should == 'create'
      version.main.should == person
    end

    it 'sets main on update' do
      account = person.social_accounts.create(label: 'Foo', name: 'Bar')
      expect do
        account.update_attributes!(name: 'Bur')
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at).last
      version.event.should == 'update'
      version.main.should == person
    end

    it 'sets main on destroy' do
      account = person.social_accounts.create(label: 'Foo', name: 'Bar')
      expect do
        account.destroy!
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at).last
      version.event.should == 'destroy'
      version.main.should == person
    end
  end
end
