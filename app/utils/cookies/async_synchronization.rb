#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Cookies::AsyncSynchronization < Cookie
  NAME = :async_synchronizations
  ATTRIBUTES = :mailing_list_id

  def initialize(cookies)
    super(cookies, NAME, ATTRIBUTES)
  end
end
