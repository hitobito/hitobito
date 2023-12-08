# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistration do
  let(:params) { {} }
  let(:role_type) { Group::TopGroup::Member }
  let(:group) { groups(:top_group) }

  subject(:registration) { described_class.new(group: group, params: params) }

  describe 'populating step and next' do
    it 'step defaults to 0' do
      expect(registration.step).to eq 0
    end

    it 'step is set according to param' do
      params[:step] = 1
      expect(registration.step).to eq 1
    end

    it '#move_on does not move if next is blank' do
      expect { registration.move_on }.not_to change { registration.step }
    end

    it '#move_on does move if next is present' do
      params[:step] = 2
      params[:next] = 4
      expect { registration.move_on }.to change { registration.step }.from(2).to(4)
    end
  end

  describe 'populating main_person' do
    it 'does not fail on empty params' do
      expect { registration }.not_to raise_error
    end

    it 'does populate person attrs' do
      params[:self_registration] = { main_person_attributes: { first_name: 'test' } }
      expect(registration.main_person_attributes).to be_present
      expect(registration.main_person.first_name).to eq 'test'
      expect(registration.main_person).to be_kind_of(SelfRegistration::MainPerson)
    end

    it 'can also populate via attr accessors' do
      registration.main_person_attributes = { first_name: 'test' }
      expect(registration.main_person_attributes).to be_present
      expect(registration.main_person.first_name).to eq 'test'
      expect(registration.main_person).to be_kind_of(SelfRegistration::MainPerson)
    end
  end

  context 'with self_registration_role_type on group' do
    before { group.update!(self_registration_role_type: role_type) }

    describe 'validations' do
      it 'is invalid if attributes are not present' do
        expect(registration).not_to be_valid
        expect(registration.main_person.errors).to have(2).item
        expect(registration.main_person.errors[:first_name][0]).to eq 'muss ausgefüllt werden'
        expect(registration.main_person.errors[:last_name][0]).to eq 'muss ausgefüllt werden'
      end

      it 'is valid if required attributes are present' do
        registration.main_person_attributes = { first_name: 'test', last_name: 'test' }
        expect(registration.main_person).to be_valid
      end

      describe 'activating step according to validations' do
        before do
          params[:step] = 1
          params[:next] = 2
          registration.partials = [:a, :b, :c]
        end

        it 'validates up to next step' do
          expect(registration).to receive(:a_valid?)
          expect(registration).to receive(:b_valid?)
          expect(registration).not_to receive(:c_valid?)
          registration.valid?
        end

        it 'sets step according to validation result' do
          expect(registration).to receive(:a_valid?).and_return(false)
          expect(registration).to receive(:b_valid?).and_return(true)
          expect do
            expect(registration).not_to be_valid
          end.to change { registration.step }.from(1).to(0)
        end
      end
    end

    describe '#save!' do
      it 'saves person with role without household key' do
        registration.main_person_attributes = { first_name: 'test' }
        expect { registration.save! }.to change { Person.count }.by(1)
          .and change { group.roles.where(type: role_type.sti_name).count }.by(1)
        expect(Person.find_by(first_name: 'test').household_key).to be_nil
      end

      it 'raises if save! fails' do
        registration.main_person_attributes = { email: 'top.leader@example.com' }
        expect { registration.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
