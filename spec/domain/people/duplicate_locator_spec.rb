# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe People::DuplicateLocator do

  let(:checker) { described_class.new }

  context 'check' do
    it 'creates one duplicate entry when all attributes match once' do
      duplicate = create_duplicate(:top_leader)
      expect { checker.run }.to change { PersonDuplicate.count }.by(1)
      person_duplicate = PersonDuplicate.find_by(person_1: people(:top_leader), person_2: duplicate)

      expect(person_duplicate).to_not be_nil
    end

    it 'creates two duplicate entries when all attributes match twice' do
      duplicate_1 = create_duplicate(:top_leader)
      duplicate_2 = create_duplicate(:top_leader)
      expect { checker.run }.to change { PersonDuplicate.count }.by(2)

      person_duplicate_1 = PersonDuplicate.find_by(person_1: people(:top_leader), person_2: duplicate_1)
      person_duplicate_2 = PersonDuplicate.find_by(person_1: people(:top_leader), person_2: duplicate_2)

      expect(person_duplicate_1).to_not be_nil
      expect(person_duplicate_2).to_not be_nil
    end

    it 'creates one duplicate entry for matching name, company name, birthday but blank zip code' do
      duplicate = create_duplicate(:top_leader)
      duplicate.update!(zip_code: nil)
      expect { checker.run }.to change { PersonDuplicate.count }.by(1)

      person_duplicate = PersonDuplicate.find_by(person_1: people(:top_leader), person_2: duplicate)

      expect(person_duplicate).to_not be_nil
    end

    it 'creates one duplicate entry for matching name, company name, zip code but blank birthday' do
      duplicate = create_duplicate(:top_leader)
      duplicate.update!(birthday: nil)
      expect { checker.run }.to change { PersonDuplicate.count }.by(1)

      person_duplicate = PersonDuplicate.find_by(person_1: people(:top_leader), person_2: duplicate)

      expect(person_duplicate).to_not be_nil
    end

    it 'creates one duplicate entry for matching name, company name but blank birthday, zip code' do
      duplicate = create_duplicate(:top_leader)
      duplicate.update!(birthday: nil, zip_code: nil)
      expect { checker.run }.to change { PersonDuplicate.count }.by(1)

      person_duplicate = PersonDuplicate.find_by(person_1: people(:top_leader), person_2: duplicate)

      expect(person_duplicate).to_not be_nil
    end

    it 'creates no duplicate entry when duplicate already exists' do
      duplicate = create_duplicate(:top_leader)
      PersonDuplicate.create!(person_1: duplicate, person_2: people(:top_leader))
      expect { checker.run }.to_not change { PersonDuplicate.count }
    end

    it 'creates no duplicate entry when no attributes match' do
      expect { checker.run }.to_not change { PersonDuplicate.count }
    end

    it 'creates no duplicate entry if first_name does not match' do
      create_duplicate(:top_leader).update!(first_name: 'Bottom')
      expect { checker.run }.to_not change { PersonDuplicate.count }
    end

    it 'creates no duplicate entry if last_name does not match' do
      create_duplicate(:top_leader).update!(first_name: 'Member')
      expect { checker.run }.to_not change { PersonDuplicate.count }
    end

    it 'creates no duplicate entry if company_name does not match' do
      create_duplicate(:top_leader).update!(company_name: 'Company')
      expect { checker.run }.to_not change { PersonDuplicate.count }
    end
  end

  private

  def create_duplicate(name)
    duplicate = people(name).dup
    duplicate.email = nil
    duplicate.save!
    duplicate
  end
end
