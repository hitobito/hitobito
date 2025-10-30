#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Copies all validators that are defined for globalized attributes to their
# associated globalized accessors. We do this after a class has been loaded
# since we cant know if the validators are always defined before the globalization
# happens. If we do it like this we can ensure both things have happened before copying
# the validators.
Rails.autoloaders.main.on_load do |_, value|
  if value.is_a?(Class) && value.ancestors.include?(Globalized)
    value.copy_validators_to_globalized_accessors
  end
end
