# encoding: utf-8

#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
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

  after do
    I18n.locale = I18n.default_locale
  end

  context 'validation' do
    it 'uses devise regexp for email' do
      a1 = Fabricate(:additional_email, label: 'Foo')
      a1.should be_valid

      a1.email = 'foo'
      a1.should_not be_valid
    end
  end

  context '#translated_label' do
    it 'should return untranslated label as-is' do
      I18n.locale = :fr

      a1 = Fabricate(:additional_email, label: 'Foo')
      a1.label.should eq 'Foo'
      a1.translated_label.should eq 'Foo'
    end

    it 'should return translated label' do
      I18n.locale = :fr

      a2 = Fabricate(:additional_email, label: 'Privat')
      a2.label.should eq 'Privat'
      a2.translated_label.should eq 'Privé'
    end
  end

  context '.normalize_label' do
    it 'reuses existing label' do
      a1 = Fabricate(:additional_email, label: 'Foo')
      a2 = Fabricate(:additional_email, label: 'fOO')
      a2.label.should == 'Foo'
    end

    it 'should preserve untranslated label as-is' do
      I18n.locale = :fr

      a1 = Fabricate(:additional_email, label: 'Foo')
      a1.label.should eq 'Foo'
    end

    it 'should map label back to default language' do
      I18n.locale = :fr

      a2 = Fabricate(:additional_email, label: 'privé')
      a2.label.should eq 'Privat'
    end
  end

  context '#available_labels' do
    subject { AdditionalEmail.available_labels }
    before do
      @settings_langs = Settings.application.languages
      Settings.application.languages = { de: 'Deutsch', fr: 'Français' }
    end
    after do
      Settings.application.languages = @settings_langs
    end
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

    it 'includes translated labels where available' do
      I18n.locale = :fr

      a1 = Fabricate(:additional_email, label: 'Foo')
      a2 = Fabricate(:additional_email, label: 'Privat')

      should include('Foo', 'Privé')
    end

    it 'is sweeped for all languages if new label is added' do
      Rails.cache.clear

      I18n.locale.should eq :de
      labels_de = AdditionalEmail.available_labels

      I18n.locale = :fr
      labels_fr = AdditionalEmail.available_labels

      labels_de.should_not eq labels_fr

      a1 = Fabricate(:additional_email, label: 'A new label')
      AdditionalEmail.available_labels.should eq labels_fr + ['A new label']

      I18n.locale = :de
      AdditionalEmail.available_labels.should eq labels_de + ['A new label']
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
