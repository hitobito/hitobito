# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PhoneNumber do

  context '.normalize_label' do

    it 'reuses existing label' do
      a1 = Fabricate(:phone_number, label: 'privat')
      a1.label.should == 'Privat'
    end
  end

  context '#available_labels' do
    subject { PhoneNumber.available_labels }
    it { should include(Settings.phone_number.predefined_labels.first) }

    it 'includes labels from database' do
      a = Fabricate(:phone_number, label: 'Foo')
      should include('Foo')
    end

    it 'includes labels from database and predefined only once' do
      predef = Settings.phone_number.predefined_labels.first
      a = Fabricate(:phone_number, label: predef)
      subject.count(predef).should == 1
    end
  end

  context 'paper trails', versioning: true do
    let(:person) { people(:top_leader) }

    it 'sets main on create' do
      expect do
        person.phone_numbers.create!(label: 'Foo', number: 'Bar')
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      version.event.should == 'create'
      version.main.should == person
    end

    it 'sets main on update' do
      account = person.phone_numbers.create(label: 'Foo', number: 'Bar')
      expect do
        account.update_attributes!(number: 'Bur')
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      version.event.should == 'update'
      version.main.should == person
    end

    it 'sets main on destroy' do
      account = person.phone_numbers.create(label: 'Foo', number: 'Bar')
      expect do
        account.destroy!
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      version.event.should == 'destroy'
      version.main.should == person
    end
  end
end
