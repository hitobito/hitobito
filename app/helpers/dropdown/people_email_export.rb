#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class PeopleEmailExport < Base
    attr_reader :user, :params

    def initialize(template, user, params, options = {})
      super(template, translate(:button), :download)
      @user = user
      @params = params

      add_email_item(:emails_comma_separated, :email)
      add_email_item(:emails_semicolon_separated, :email_outlook)
    end

    def add_email_item(key, format)
      add_item(translate(key), params.merge(format:), target: :_blank)
    end
  end
end
