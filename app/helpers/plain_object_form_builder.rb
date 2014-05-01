# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PlainObjectFormBuilder < StandardFormBuilder
  def required?(_attr)
    false
  end

  def errors_on?(_attr)
    false
  end
end
