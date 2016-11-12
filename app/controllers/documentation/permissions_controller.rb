# encoding: utf-8

#  Copyright (c) 2012-2016, Puzzle ITC GmbH. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Documentation
  class PermissionsController < ApplicationController

    skip_authorization_check

    def roles; end

    def abilities; end

  end
end
