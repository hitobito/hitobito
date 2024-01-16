# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

require 'spec_helper'

describe People::DuplicateLocatorJob do
  let(:person) { people(:bottom_member) }
  let(:top_group) { groups(:top_group) }
  let(:role_type) { Group::TopGroup::Member.sti_name }
  let(:tomorrow) { Time.zone.tomorrow }

  before do
    # job is mocked in test env, see spec_helper
    allow(People::DuplicateLocatorJob).to receive(:new).and_call_original
  end

  context 'with no job arguments' do
    subject(:job) { described_class.new }

    it 'Runs job concerning all person entries' do
      expect(People::DuplicateLocator).to receive(:new)
        .with(no_args)
        .and_call_original

      job.perform
    end
  end

  context 'with specific person id' do
    let(:people_ids) { Person.first.id }
    subject(:job) { described_class.new(people_ids) }

    it 'Runs job for a single person entry' do
      people_scope = Person.where(id: Person.first.id)
      expect(People::DuplicateLocator).to receive(:new)
        .with(people_scope)
        .and_call_original

      job.perform
    end
  end
end
