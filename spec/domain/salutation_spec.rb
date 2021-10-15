# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

require 'spec_helper'

describe Salutation do

  let(:person)     { people(:top_leader) }
  let(:salutation) { Salutation.new(person) }

  context '.available' do
    subject { Salutation.available }

    it { expect(subject).to have(1).items }
  end

  context '#label' do
    subject { salutation.label }

    it { expect(subject).to eq('Hallo [Name]') }
  end

  context '#value' do
    subject { salutation.value }

    context 'male' do
      before { person.gender = 'm' }
      it { expect(subject).to eq('Hallo Top') }
    end

    context 'female' do
      before { person.gender = 'w' }
      it { expect(subject).to eq('Hallo Top') }
    end

    context 'no gender' do
      before { person.gender = nil }
      it { expect(subject).to eq('Hallo Top') }
    end
  end

  context '#value_for_household' do

    def create_person(first_name, last_name, salutation = :lieber_vorname)
      Fabricate(:person, first_name: first_name, last_name: last_name).tap do |p|
        allow(p).to receive(:salutation).and_return(salutation)
        allow(p).to receive(:salutation?).and_return(true)
      end
    end

    before do
      person.update(
          first_name: 'John',
          last_name: 'Doe'
      )
      allow(person).to receive(:salutation).and_return(:default)
    end

    context 'using personal salutation' do

      let(:subject) { Salutation.new(person, 'personal') }

      it 'handles a single person' do
        expect(subject.value_for_household([person]))
            .to eq "Hallo John"
      end

      it 'handles two people' do
        person2 = create_person('Jane', person.last_name)

        expect(subject.value_for_household([person, person2]))
            .to eq "Hallo John, liebe*r Jane"
      end

      it 'handles more than two people' do
        person2 = create_person('Jane', 'Foo')
        person3 = create_person('Betty', 'Baz')
        person4 = create_person('Charlotte', 'Baz')
        person5 = create_person('Daniel', 'Baz')

        expect(subject.value_for_household([person, person2, person3, person4, person5]))
            .to eq "Hallo John, liebe*r Jane, liebe*r Betty, liebe*r Charlotte, liebe*r Daniel"
      end

    end

    context 'when given letter salutation' do

      let(:subject) { Salutation.new(person, :default) }

      before do
        allow(person).to receive(:salutation).and_return(:lieber_vorname)
      end

      it 'handles a single person' do
        expect(subject.value_for_household([person]))
            .to eq "Hallo John"
      end

      it 'handles two people' do
        person2 = create_person('Jane', person.last_name)

        expect(subject.value_for_household([person, person2]))
            .to eq "Hallo John, hallo Jane"
      end

      it 'handles more than two people' do
        person2 = create_person('Jane', 'Foo')
        person3 = create_person('Betty', 'Baz')
        person4 = create_person('Charlotte', 'Baz')
        person5 = create_person('Daniel', 'Baz')

        expect(subject.value_for_household([person, person2, person3, person4, person5]))
            .to eq "Hallo John, hallo Jane, hallo Betty, hallo Charlotte, hallo Daniel"
      end

    end
  end

  context '#value_for_household' do

    def create_person(first_name, last_name, salutation = :lieber_vorname)
      Fabricate(:person, first_name: first_name, last_name: last_name).tap do |p|
        allow(p).to receive(:salutation).and_return(salutation) if salutation.present?
        allow(p).to receive(:salutation?).and_return(true) if salutation.present?
      end
    end

    before do
      person.update(
          first_name: 'John',
          last_name: 'Doe'
      )
    end

    context 'using personal salutation' do

      before do
        allow(person).to receive(:salutation).and_return(:default)
      end

      let(:subject) { Salutation.new(person, 'personal') }

      it 'handles a single person' do
        expect(subject.value_for_household([person]))
            .to eq "Hallo John"
      end

      it 'handles two people' do
        person2 = create_person('Jane', person.last_name)

        expect(subject.value_for_household([person, person2]))
            .to eq "Hallo John, liebe*r Jane"
      end

      it 'handles more than two people' do
        person2 = create_person('Jane', 'Foo')
        person3 = create_person('Betty', 'Baz')
        person4 = create_person('Charlotte', 'Baz')
        person5 = create_person('Daniel', 'Baz')

        expect(subject.value_for_household([person, person2, person3, person4, person5]))
            .to eq "Hallo John, liebe*r Jane, liebe*r Betty, liebe*r Charlotte, liebe*r Daniel"
      end

    end

    context 'when given letter salutation' do

      before do
        allow(person).to receive(:salutation).and_return(:default)
      end

      let(:subject) { Salutation.new(person, :default) }

      before do
        allow(person).to receive(:salutation).and_return(:lieber_vorname)
      end

      it 'handles a single person' do
        expect(subject.value_for_household([person]))
            .to eq "Hallo John"
      end

      it 'handles two people' do
        person2 = create_person('Jane', person.last_name)

        expect(subject.value_for_household([person, person2]))
            .to eq "Hallo John, hallo Jane"
      end

      it 'handles more than two people' do
        person2 = create_person('Jane', 'Foo')
        person3 = create_person('Betty', 'Baz')
        person4 = create_person('Charlotte', 'Baz')
        person5 = create_person('Daniel', 'Baz')

        expect(subject.value_for_household([person, person2, person3, person4, person5]))
            .to eq "Hallo John, hallo Jane, hallo Betty, hallo Charlotte, hallo Daniel"
      end

    end

    context 'in wagons that have no salutation' do

      let(:subject) { Salutation.new(person, :default) }

      it 'handles a single person' do
        expect(subject.value_for_household([person]))
            .to eq "Hallo John"
      end

      it 'handles two people' do
        person2 = create_person('Jane', person.last_name, nil)

        expect(subject.value_for_household([person, person2]))
            .to eq "Hallo John, hallo Jane"
      end

      it 'handles more than two people' do
        person2 = create_person('Jane', 'Foo', nil)
        person3 = create_person('Betty', 'Baz', nil)
        person4 = create_person('Charlotte', 'Baz', nil)
        person5 = create_person('Daniel', 'Baz', nil)

        expect(subject.value_for_household([person, person2, person3, person4, person5]))
            .to eq "Hallo John, hallo Jane, hallo Betty, hallo Charlotte, hallo Daniel"
      end

    end
  end
end
