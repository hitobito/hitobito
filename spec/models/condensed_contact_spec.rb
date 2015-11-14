# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe CondensedContact do
  let(:person) { Fabricate(:person_with_address_and_phone) }
  let(:condensable_person) { Person.create(person.attributes.merge({id: nil, first_name: Faker::Name.first_name})) }
  let(:noncondensable_person) { Person.create(person.attributes.merge({id: nil, last_name: Faker::Name.last_name})) }
  let(:condensed_contact) { CondensedContact.new(person) }

  def condensed_attributes(contactable)
    contactable.attributes.with_indifferent_access.slice(:address, :last_name, :zip_code, :town, :country)
  end

  context 'without merged contactable' do
    describe '#initialize' do
      subject { condensed_contact }

      it { is_expected.to have_attributes(condensed_attributes(person)) }
      its(:base_contactable) { is_expected.to be person }
    end

    describe '#contactables' do
      subject { condensed_contact.condensed_contactables }

      it { is_expected.to eq([person]) }
    end

    describe '#mergeable?' do
      context 'with mergeable contact' do
        subject { condensed_contact.condensable?(condensable_person) }

        it { is_expected.to be true }
      end

      context 'with nonmergeable contact' do
        subject { condensed_contact.condensable?(noncondensable_person) }

        it { is_expected.to be false }
      end
    end

    describe '#merge' do
      context 'with mergeable contact' do
        subject { condensed_contact.condense(condensable_person) }

        it 'merges the contact' do
          expect { subject }.to change { condensed_contact.condensed_contactables }
        end

        it 'does not merge twice' do
          subject
          expect { condensed_contact.condense(condensable_person) }.
            not_to change { condensed_contact.condensed_contactables }
        end
      end

      context 'with nonmergeable contact' do
        subject { condensed_contact.condense(noncondensable_person) }

        it 'does not merge the contact' do
          expect { subject }.not_to change { condensed_contact.condensed_contactables }
        end
      end
    end
  end

  context 'with merged contactable' do
    let(:merged_condensed_contact) { CondensedContact.new(person, [condensable_person]) }

    describe '#full_name' do
      subject { merged_condensed_contact.full_name }

      it { is_expected.to eq("#{[person.first_name, condensable_person.first_name].to_sentence} #{person.last_name}") }
    end
  end

  describe '::condense_list' do
    let(:condensable_list) { [person, condensable_person, noncondensable_person] }
    subject { CondensedContact.condense_list(condensable_list) }

    its(:count) { is_expected.to be 2 }
  end
end
