# frozen_string_literal: true

#  Copyright (c) 2021-2022, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupSettingDecorator < ApplicationDecorator
  include UploadDisplayHelper

  def translated_values
    object.attrs.collect do |a|
      "#{t(a)}: #{formatted_value(a)}"
    end.join(', ')
  end

  def to_s
    name
  end

  def name
    t("settings.#{object.var}")
  end

  private

  def t(key)
    prefix = 'activerecord.attributes.group_setting'
    I18n.t("#{prefix}.#{key}")
  end

  def formatted_value(attr)
    return '****' if attr.eql?(:password)
    return picture_file_name if attr.eql?(:picture)

    value = object.send(attr)
    value || '-'
  end

  def picture_file_name
    upload_name(object, :picture) || '-'
  end

end
