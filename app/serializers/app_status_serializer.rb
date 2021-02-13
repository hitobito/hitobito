# encoding: utf-8

#  Copyright (c) 2017, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AppStatusSerializer
  delegate :code, :details, to: :app_status

  attr_reader :app_status

  def initialize(app_status)
    @app_status = app_status
  end

  def to_json(_a)
    {app_status: {code: code, details: details}}.to_json
  end
end
