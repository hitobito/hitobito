# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module ActiveModelTypes
  class Reference < ActiveModel::Type::BigInteger
    attr_reader :reference_class

    def initialize(reference_class)
      @reference_class = reference_class
    end
  end
end
