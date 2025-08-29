#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Rails.application.config.to_prepare do
  Rails.autoloaders.main.on_load do |_, value|
    value.send(:copy_validators_to_globalized_accessors) if value.include?(Globalized)
  end
end
