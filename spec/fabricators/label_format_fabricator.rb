# encoding: utf-8

#  Copyright (c) 2014, Insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


Fabricator(:label_format) do
  name { Faker::Name.first_name }
  page_size { 'A4' }
  landscape { false }
  font_size { 12 }
  width     { 60 }
  height    { 30 }
  count_horizontal { 3 }
  count_vertical   { 8 }
  padding_top      { 5 }
  padding_left     { 5 }
end
