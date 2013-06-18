module Export
  module CsvPeople
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
        Export::CsvPeople::Participation.new(participation)
      end

      def add_event_specifics
      end
    end
  end
end
