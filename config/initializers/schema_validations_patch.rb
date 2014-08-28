# encoding: utf-8

#  Copyright (c) 2012-2014, insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# patches schema validations for rails 4.1. should not be required for version after 1.0.0
module ActiveRecord
  class Base
    protected

    def run_validations_with_schema_validations!
      load_schema_validations unless schema_validations_loaded?
      run_validations_without_schema_validations!
    end
    alias_method_chain :run_validations!, :schema_validations
  end
end