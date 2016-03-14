# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

require 'spec_helper'

describe Person::Note do
  context 'dependent destroy' do
    let(:person) { Fabricate(:person) }
    let(:author) { Fabricate(:person) }

    it 'gets destroyed if the person is destroyed' do
      person.notes.create!(author_id: author.id, text: 'Lorem ipsum')
      expect(Person::Note.count).to eq(1)
      person.destroy!
      expect(Person::Note.count).to eq(0)
    end

    it 'gets destroyed if the author is destroyed' do
      person.notes.create!(author_id: author.id, text: 'Lorem ipsum')
      expect(Person::Note.count).to eq(1)
      author.destroy!
      expect(Person::Note.count).to eq(0)
    end
  end
end
