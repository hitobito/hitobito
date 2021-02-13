#  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Cookies::AsyncDownload < Cookie
  NAME = :async_downloads
  ATTRIBUTES = [:name, :type].freeze

  def initialize(cookies)
    super(cookies, NAME, ATTRIBUTES)
  end
end
