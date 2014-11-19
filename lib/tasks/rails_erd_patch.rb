# encoding: UTF-8

require 'rails_erd/domain/relationship'

module RailsERD
  class Domain
    class Relationship
      class << self
        private

        def association_identity(association)
          # do not include identifier in Set to avoid multiple relations between two models,
          # as this may cause segmentation faults in Graphviz.
          Set[association_owner(association), association_target(association)]
        end
      end
    end
  end
end
