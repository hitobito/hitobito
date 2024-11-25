#  Copyright (c) 2014, Insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: label_formats
#
#  id               :integer          not null, primary key
#  count_horizontal :integer          not null
#  count_vertical   :integer          not null
#  font_size        :float            default(11.0), not null
#  height           :float            not null
#  landscape        :boolean          default(FALSE), not null
#  name             :string           not null
#  nickname         :boolean          default(FALSE), not null
#  padding_left     :float            not null
#  padding_top      :float            not null
#  page_size        :string           default("A4"), not null
#  pp_post          :string(23)
#  width            :float            not null
#  person_id        :integer
#

Fabricator(:label_format) do
  name { Faker::Name.first_name }
  page_size { "A4" }
  landscape { false }
  font_size { 12 }
  width { 60 }
  height { 30 }
  count_horizontal { 3 }
  count_vertical { 8 }
  padding_top { 5 }
  padding_left { 5 }
end
