#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class PeopleEmailExport < Base
    attr_reader :user, :params

    def initialize(template, user, params, options = {})
      super(template, translate(:button), :download)
      _, _, _ = true
      @user = user
      @params = params

      add_item(translate(:emails_comma_separated), params.merge(format: :email), target: :_blank)
      add_item(translate(:emails_semicolon_separated), params.merge(format: :email), target: :_blank)
    end
  end
end
