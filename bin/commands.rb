# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

#require 'active_support/core_ext/object/inclusion'

aliases = {
  "g"  => "generate",
  "d"  => "destroy",
  "c"  => "console",
  "s"  => "server",
  "db" => "dbconsole",
  "r"  => "runner"
}

command = ARGV.shift
command = aliases[command] || command

case command
when 'console'
  require 'rails/commands/console'
  require APP_PATH
  Rails.application.require_environment!
  
  ### ADDED THIS LINE FOR FINE-GRAINED BUNDLER GROUPS
  Bundler.require(:console)
  
  Rails::Console.start(Rails.application)

when 'server'
  # Change to the application's path if there is no config.ru file in current dir.
  # This allows us to run script/rails server from other directories, but still get
  # the main config.ru and properly set the tmp directory.
  Dir.chdir(File.expand_path('../../', APP_PATH)) unless File.exists?(File.expand_path("config.ru"))

  require 'rails/commands/server'
  Rails::Server.new.tap { |server|
    # We need to require application after the server sets environment,
    # otherwise the --environment option given to the server won't propagate.
    require APP_PATH
    
    ### ADDED THIS LINE FOR FINE-GRAINED BUNDLER GROUPS
    Bundler.require(:assets)
    
    Dir.chdir(Rails.application.root)
    server.start
  }

else
  ARGV.unshift(command)
  require 'rails/commands'
end
