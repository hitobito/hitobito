# encoding: utf-8

#  Copyright (c) 2014 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PaperTrail::VersionDecorator, :draper_with_helpers, versioning: true do

  include Rails.application.routes.url_helpers

  let(:person)    { people(:top_leader) }
  let(:version)   { PaperTrail::Version.where(main_id: person.id).order(:created_at, :id).last }
  let(:decorator) { PaperTrail::VersionDecorator.new(version) }

  before { PaperTrail.whodunnit = nil }

  context '#header' do
    subject { decorator.header }

    context 'without current user' do
      before { update_attributes }
      it { should =~ /^\w+, \d+\. [\w|ä]+ \d{4}, \d{2}:\d{2} Uhr$/ }
    end

    context 'with current user' do
      before do
        PaperTrail.whodunnit = person.id.to_s
        update_attributes
      end

      it { should =~ /^\w+, \d+\. [\w|ä]+ \d{4}, \d{2}:\d{2} Uhr<br \/>von <a href=".+">#{person.to_s}<\/a>$/ }
    end
  end

  context '#author' do
    subject { decorator.author }

    context 'without current user' do
      before { update_attributes }
      it { should be_nil }
    end

    context 'with current user' do
      before do
        PaperTrail.whodunnit = person.id.to_s
        update_attributes
      end

      context 'and permission to link' do
        it do
          decorator.h.should_receive(:can?).with(:show, person).and_return(true)
          should =~ /^<a href=".+">#{person.to_s}<\/a>$/
        end
      end

      context 'and no permission to link' do
        it do
          decorator.h.should_receive(:can?).with(:show, person).and_return(false)
          should == person.to_s
        end
      end
    end
  end

  context '#changes' do

    subject { decorator.changes }

    context 'with attribute changes' do
      before { update_attributes }

      it { should =~ /<div>Ort wurde.+<div>PLZ wurde.+<div>Haupt-E-Mail wurde/ }
    end

    context 'with association changes' do
      before { Fabricate(:social_account, contactable: person, label: 'Foo', name: 'Bar') }

      it { should =~ /<div>Social Media/ }
    end
  end

  context '#attribute_change' do
    before { update_attributes }

    it 'contains from and to attributes' do
      string = decorator.attribute_change(:first_name, 'Hans', 'Fritz')
      string.should be_html_safe
      string.should == 'Vorname wurde von <i>Hans</i> auf <i>Fritz</i> geändert.'
    end

    it 'contains only from attribute' do
      string = decorator.attribute_change(:first_name, 'Hans', ' ')
      string.should be_html_safe
      string.should == 'Vorname <i>Hans</i> wurde gelöscht.'
    end

    it 'contains only to attribute' do
      string = decorator.attribute_change(:first_name, nil, 'Fritz')
      string.should be_html_safe
      string.should == 'Vorname wurde auf <i>Fritz</i> gesetzt.'
    end

    it 'is empty without from and to ' do
      string = decorator.attribute_change(:first_name, nil, '')
      string.should be_blank
    end

    it 'escapes html' do
      string = decorator.attribute_change(:first_name, nil, '<b>Fritz</b>')
      string.should == 'Vorname wurde auf <i>&lt;b&gt;Fritz&lt;/b&gt;</i> gesetzt.'
    end

    it 'formats according to column info' do
      now = Time.local(2014, 6, 21, 18)
      string = decorator.attribute_change(:updated_at, nil, now)
      string.should eq 'Geändert wurde auf <i>21.06.2014 18:00</i> gesetzt.'
    end
  end

  context '#association_change' do
    subject { decorator.association_change }

    it 'builds create text' do
      Fabricate(:social_account, contactable: person, label: 'Foo', name: 'Bar')

      should == 'Social Media Adresse <i>Bar (Foo)</i> wurde hinzugefügt.'
    end

    it 'builds update text' do
      account = Fabricate(:social_account, contactable: person, label: 'Foo', name: 'Bar')
      account.update_attributes!(name: 'Boo')

      should == 'Social Media Adresse <i>Bar (Foo)</i> wurde aktualisiert: Name wurde von <i>Bar</i> auf <i>Boo</i> geändert.'
    end

    it 'builds destroy text' do
      account = Fabricate(:social_account, contactable: person, label: 'Foo', name: 'Bar')
      account.destroy!

      should == 'Social Media Adresse <i>Bar (Foo)</i> wurde gelöscht.'
    end
  end

  def update_attributes
    person.update_attributes!(town: 'Bern', zip_code: '3007', email: 'new@hito.example.com')
  end

end
