# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistration::MainPerson do
  subject(:model) { described_class.new }

  it 'is a Housemate' do
    expect(model).to be_kind_of(SelfRegistration::Housemate)
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
