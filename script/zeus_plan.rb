# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'zeus/rails'
class MyPlan < Zeus::Rails
  def server_environment
    Bundler.require(:assets)
  end
  def development_environment
    Bundler.require(:development, :assets)
    ::Rails.env = ENV['RAILS_ENV'] = "development"
    require APP_PATH
    ::Rails.application.require_environment!
  end

end
Zeus.plan = MyPlan.new
