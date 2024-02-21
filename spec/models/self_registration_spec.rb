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

  it 'step defaults to 0' do
    expect(registration.step).to eq 0
  end

  it 'step is set according to param' do
    params[:step] = 1
    expect(registration.step).to eq 1
  end

  describe '#move_on' do
    it 'moves one step if partial is valid' do
      registration.partials = [:a]
      expect(registration).to receive(:a_valid?).and_return(true)
      expect { registration.move_on }.to change { registration.step }.from(0).to(1)
    end

    it 'stays on current step if partial is invalid' do
      registration.partials = [:a]
      expect(registration).to receive(:a_valid?).and_return(false)
      expect { registration.move_on }.not_to change { registration.step }
    end

    it 'stays on current step if partial is valid but next is set to current step' do
      params[:step] = 1
      params[:next] = 1
      registration.partials = [:a, :b, :c]

      expect(registration.step).to eq 1
      expect(registration).to receive(:a_valid?).and_return(true)
      expect(registration).to receive(:b_valid?).and_return(true)
      expect { registration.move_on }.not_to change { registration.step }
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
    end

    describe '#save!' do
      it 'saves person with role without household key' do
        registration.main_person_attributes = { first_name: 'test' }
        expect { registration.save! }.to change { Person.count }.by(1)
          .and change { group.roles.where(type: role_type.sti_name).count }.by(1)
        expect(Person.find_by(first_name: 'test').household_key).to be_nil
      end

      it 'enqueues DuplicateLocatorJob for newly created person' do
        registration.main_person_attributes = { first_name: 'test' }
        registration.save!
        person = Person.find_by(first_name: 'test')
        job = Delayed::Job.find_by("handler like '%Person::DuplicateLocatorJob%person_id: #{person.id}%'")
        expect(job).to be_present
      end

      it 'raises if save! fails' do
        registration.main_person_attributes = { email: 'top.leader@example.com' }
        expect { registration.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
