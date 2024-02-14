# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistration::MainPerson do
  subject(:model) { described_class.new }
  let(:group) { groups(:top_group) }

  it 'is a Housemate' do
    expect(model).to be_kind_of(SelfRegistration::Person)
  end

  describe 'attribute assignments accept additiional attributes' do
    it 'works via constructor for symbols' do
      expect(described_class.new(first_name: 'test').first_name).to eq 'test'
    end
  end

  describe 'validations' do
    it 'validates 2 fields' do
      expect(model).not_to be_valid
      expect(model.errors).to have(2).items
    end

    context 'with group requiring adult consent' do
      let(:required_attrs) { { first_name: 'test', last_name: 'dummy' } }
      before do
        group.update!(
          self_registration_require_adult_consent: true,
          self_registration_role_type: group.role_types.first
        )
        model.primary_group = group
        model.attributes = required_attrs
      end

      it 'is valid when adult consent is not explicitly denied' do
        expect(model).to be_valid
      end

      it 'is valid when adult consent is explicitly set' do
        model.adult_consent = '1'
        expect(model).to be_valid
      end

      it 'is invalid when adult consent is explicitly denied' do
        model.adult_consent = '0'
        expect(model).not_to be_valid
        expect(model).to have(1).error_on(:adult_consent)
      end
    end
  end

  describe 'privacy policy' do
    it 'assigns value' do
      model.privacy_policy_accepted = '1'
      expect(model.person.privacy_policy_accepted).to be_truthy
    end

    it 'validates that policy is accepted' do
      model.privacy_policy_accepted = '0'
      expect(model).not_to be_valid
      expect(model).to have(1).error_on(:base)
      expect(model.errors[:base].first).to start_with 'Um die Registrierung'
    end
  end
end
