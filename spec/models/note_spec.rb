# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

# == Schema Information
#
# Table name: person_notes
#
#  id         :integer          not null, primary key
#  person_id  :integer          not null
#  author_id  :integer          not null
#  text       :text
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Note do
  context 'dependent destroy' do
    let(:subject) { Fabricate(:person) }
    let(:author) { Fabricate(:person) }

    it 'gets destroyed if the person is destroyed' do
      subject.notes.create!(author_id: author.id, text: 'Lorem ipsum')
      expect(Note.count).to eq(1)
      subject.destroy!
      expect(Note.count).to eq(0)
    end

    it 'gets destroyed if the author is destroyed' do
      subject.notes.create!(author_id: author.id, text: 'Lorem ipsum')
      expect(Note.count).to eq(1)
      author.destroy!
      expect(Note.count).to eq(0)
    end
  end
end
