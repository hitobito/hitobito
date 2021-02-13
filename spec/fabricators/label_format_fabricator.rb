# encoding: utf-8
# == Schema Information
#
# Table name: label_formats
#
#  id               :integer          not null, primary key
#  page_size        :string(255)      default("A4"), not null
#  landscape        :boolean          default(FALSE), not null
#  font_size        :float(24)        default(11.0), not null
#  width            :float(24)        not null
#  height           :float(24)        not null
#  count_horizontal :integer          not null
#  count_vertical   :integer          not null
#  padding_top      :float(24)        not null
#  padding_left     :float(24)        not null
#  person_id        :integer
#  nickname         :boolean          default(FALSE), not null
#  pp_post          :string(23)
#

#  Copyright (c) 2014, Insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


Fabricator(:label_format) do
  name { Faker::Name.first_name }
  page_size { "A4" }
  landscape { false }
  font_size { 12 }
  width     { 60 }
  height    { 30 }
  count_horizontal { 3 }
  count_vertical   { 8 }
  padding_top      { 5 }
  padding_left     { 5 }
end
