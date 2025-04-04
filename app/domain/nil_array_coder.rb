# frozen_string_literal: true

#  Copyright (c) 2025-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class NilArrayCoder
  def self.dump(object)
    object.to_json # Convert Ruby array to JSON string
  end

  # Convert JSON or YAML string to array; rescue invalid data
  def self.load(data)
    YAML.parse(data).to_ruby.to_a # always return an array, even for nil
  rescue
    []
  end
end
