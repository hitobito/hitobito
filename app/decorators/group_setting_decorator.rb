# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupSettingDecorator < ApplicationDecorator

  def translated_values
    # TODO translate keys, format values, hide password
    # username: bla@mam.com, password: ****, provider: aspsms
    # seperated by new line ? br ?
    object.attrs.join(', ')
  end

  def name
    t("settings.#{object.var}")
  end

  private

  def t(key)
    prefix = 'activerecord.attributes.group_settings'
    I18n.t("#{prefix}.#{key}")
  end

end
