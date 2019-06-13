#  Copyright (c) 2019, Pfadibewegung Schweiz . This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  module Oauth
    class AccessToken < Sheet::Admin

      self.parent_sheet = Sheet::Oauth::Application

    end
  end
end
