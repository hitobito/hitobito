# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# cmess is the one actually requiring nuggets.
# only used by csv parser
require 'cmess/guess_encoding'

# for ruby < 2.2, call _nuggets_original_max/min_by only with block argument.
module Enumerable

  def max_by(by = nil, &block)
    by.nil? || by.is_a?(::Numeric) ?
      _nuggets_original_max_by(&block) : minmax_by(:max, by)
  end

  def min_by(by = nil, &block)
    by.nil? || by.is_a?(::Numeric) ?
      _nuggets_original_min_by(&block) : minmax_by(:min, by)
  end

end