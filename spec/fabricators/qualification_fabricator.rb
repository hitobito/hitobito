# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: qualifications
#
#  id                    :integer          not null, primary key
#  finish_at             :date
#  origin                :string(255)
#  start_at              :date             not null
#  person_id             :integer          not null
#  qualification_kind_id :integer          not null
#
# Indexes
#
#  index_qualifications_on_person_id              (person_id)
#  index_qualifications_on_qualification_kind_id  (qualification_kind_id)
#

Fabricator(:qualification) do
  person
  qualification_kind
  start_at (0..24).to_a.sample.months.ago
end
