# encoding: utf-8

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Session < ActiveRecord::Base

  def self.outdated
    where('updated_at < ?', 1.month.ago)
  end

end
