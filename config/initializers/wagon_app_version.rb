# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Wagons.app_version = File.read(Rails.root.join('VERSION')) rescue '0.0'

Wagons.all.each do |wagon|
  unless wagon.app_requirement.satisfied_by?(Wagons.app_version)
    raise "#{wagon.gem_name} requires application version #{wagon.app_requirement}; got #{Wagons.app_version}"
  end
end
