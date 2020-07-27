# frozen_string_literal: true

#  Copyright (c) 2012-2014, insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Cantons

  module_function

  SHORT_NAMES = [ # rubocop:disable Style/MutableConstant This is being extended in a wagon
    :ag, :ai, :ar, :be, :bl, :bs, :fr, :ge, :gl, :gr, :ju, :lu, :ne,
    :nw, :ow, :sg, :sh, :so, :sz, :tg, :ti, :ur, :vd, :vs, :zg, :zh
  ]

  def short_names
    SHORT_NAMES
  end

  def short_name_strings
    short_names.collect(&:to_s)
  end

  def full_name(shortname)
    if shortname.present?
      I18n.t("activerecord.attributes.cantons.#{shortname.to_s.downcase}")
    end
  end

  def labels
    short_names.index_with do |short|
      full_name(short)
    end
  end

end
