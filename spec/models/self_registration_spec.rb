# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistration do
  let(:params) { {} }
  let(:role_type) { Group::TopGroup::Member }
  let(:group) { groups(:top_group).tap { |g| g.update!(self_registration_role_type: role_type) } }


  subject(:registration) { build(params) }

  def build(params)
    nested_params = { self_registration: params }
    described_class.new(group: group, params: nested_params)
  end

  describe 'constructor' do
    it 'does not fail on empty params' do
      expect { build({}) }.not_to raise_error
    end

    it 'does populate person attrs' do
      registration = build(main_person_attributes: { first_name: 'test' })
      expect(registration.main_person_attributes).to be_present
      expect(registration.main_person.first_name).to eq 'test'
      expect(registration.main_person).to be_kind_of(SelfRegistration::MainPerson)
    end
  end

  describe 'validations' do
    describe 'person' do
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
