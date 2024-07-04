# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApi::DocumentationController < ApplicationController
  skip_before_action :authenticate_person!
  skip_authorization_check

  def index
  end
end
