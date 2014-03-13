# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CustomContentDecorator < ApplicationDecorator
  decorates :custom_content


  def available_placeholders
    if placeholders_required? || placeholders_optional?
      list = placeholders_list.collect do |ph|
        placeholder_token(ph)
      end
      translate(:available_placeholders, placeholders: list.join(', '))
    else
      translate(:available_placeholders_empty)
    end
  end

end
