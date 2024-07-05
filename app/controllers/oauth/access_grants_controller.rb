#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Oauth
  class AccessGrantsController < CrudController
    self.optional_nesting = Oauth::Application

    def destroy
      super(location: oauth_application_path(entry.application))
    end

    def self.model_class
      Oauth::AccessGrant
    end
  end
end
