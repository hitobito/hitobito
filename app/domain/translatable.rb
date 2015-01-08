# encoding: utf-8

#  Copyright (c) 2013-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Translatable

  private

  def translate(key, options = {})
    I18n.t(full_translation_key(key), options)
  end

  def full_translation_key(suffix)
    [translation_prefix, suffix].join('.').to_sym
  end

  def translation_prefix
    @translation_prefix ||= self.class.to_s.underscore.gsub('_controller', '')
  end

end
