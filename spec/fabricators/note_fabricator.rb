# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: notes
#
#  id           :integer          not null, primary key
#  subject_type :string
#  text         :text
#  created_at   :datetime
#  updated_at   :datetime
#  author_id    :integer          not null
#  subject_id   :integer          not null
#
# Indexes
#
#  index_notes_on_subject_id  (subject_id)
#

Fabricator(:note) do
  author { Fabricate :person }
  subject { groups(:toppers) }
  text { Faker::Quote.famous_last_words }
end
