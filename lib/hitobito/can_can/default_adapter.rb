# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_relative "condition_matching"

module Hitobito
  module CanCan
    class DefaultAdapter < ::CanCan::ModelAdapters::DefaultAdapter
      ::CanCan::ModelAdapters::AbstractAdapter.inherited(self)

      extend ConditionMatching

      def self.for_class?(model_class)
        !(model_class <= ActiveRecord::Base)
      end
    end
  end
end
