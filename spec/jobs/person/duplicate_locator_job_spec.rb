# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

require 'spec_helper'

describe Person::DuplicateLocatorJob do
  let(:person) { people(:top_leader) }
  let(:locator) { instance_double(People::DuplicateLocator) }

  it 'invoces DuplicateLocator with person scope' do
    expect(People::DuplicateLocator).to receive(:new)
      .with(Person.where(id: person.id))
      .and_return(locator)

    expect(locator).to receive(:run)
    described_class.new(person).perform
  end
end
