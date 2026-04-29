# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# Creates or updates passes for all eligible people for a given pass definition.
# Triggered when pass grants are created/updated or when pass definitions change.
# Iterates through all subscribers and ensures each has a pass with correct state.
class PassPopulateJob < BaseJob
  self.parameters = [:pass_definition_id]

  def initialize(pass_definition_id)
    super()
    @pass_definition_id = pass_definition_id
  end

  def perform
    pass_definition = PassDefinition.find(@pass_definition_id)
    subscribers = Passes::Subscribers.new(pass_definition)

    subscribers.people.find_each do |person|
      pass = Pass.find_or_initialize_by(person: person, pass_definition: pass_definition)
      Passes::PassUpdater.recompute_state!(pass)
    end
  end
end
