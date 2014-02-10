# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export
  module Csv
    module People
      module ParticipationSupport
        extend ActiveSupport::Concern

        included do
          attr_reader :participations
        end

        def initialize(participations)
          @participations = participations
          super(participations.map(&:person))
          add_event_specifics
        end

        def list
          @participations
        end

        def create(participation)
          Export::Csv::People::Participation.new(participation)
        end

        def add_event_specifics
        end
      end
    end
  end
end
