# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe FeatureGate do

  context 'person language' do
    it 'toggles language feature by given person attributes' do
      add_correspondence_language

      expect(FeatureGate.enabled?(:person_language)).to eq(false)

      drop_correspondence_language

      expect(FeatureGate.enabled?(:person_language)).to eq(true)
    end
  end

  private

  def add_correspondence_language
    return if Person.has_attribute?(:correspondence_language)

    ActiveRecord::Base.connection.execute('ALTER TABLE people ADD correspondence_language varchar(255)')
    Person.reset_column_information
  end

  def drop_correspondence_language
    ActiveRecord::Base.connection.execute('ALTER TABLE people DROP COLUMN correspondence_language')
    Person.reset_column_information
  end
end
