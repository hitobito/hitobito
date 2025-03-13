#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

formats = LabelFormat.seed(:page_size, :count_horizontal, :count_vertical,
  {page_size: 'A4',
   font_size: 11,
   width: 70,
   height: 29.7,
   padding_top: 5,
   padding_left: 5,
   count_horizontal: 3,
   count_vertical: 10 },

  {page_size: 'A4',
   font_size: 12,
   width: 105,
   height: 59.4,
   padding_top: 15,
   padding_left: 25,
   count_horizontal: 2,
   count_vertical: 5 },

  {page_size: 'C6',
   font_size: 12,
   landscape: true,
   width: 162,
   height: 114,
   padding_top: 60,
   padding_left: 80,
   count_horizontal: 1,
   count_vertical: 1},
)

LabelFormat::Translation.seed(:label_format_id, :locale,
  {label_format_id: formats[0].id,
   locale: 'de',
   name: 'Standard' },

  {label_format_id: formats[1].id,
   locale: 'de',
   name: 'Gross' },

  {label_format_id: formats[2].id,
   locale: 'de',
   name: 'Envelope' }
)
