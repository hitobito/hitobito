#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Passes::VerificationsController < ApplicationController
  skip_authorization_check
  skip_before_action :authenticate_person!
  layout false

  helper People::PassesHelper

  def show
    @pass_definition = PassDefinition.find_by(id: params[:pass_id])
    @person = Person.find_by(membership_verify_token: params[:verify_token])

    if @pass_definition.nil? || @person.nil?
      @state = :invalid
    else
      @pass = Pass.new(person: @person, definition: @pass_definition)
      @state = determine_state
    end
  end

  private

  def determine_state
    if @pass.valid?
      :valid
    elsif @pass.has_ended?
      :expired
    else
      :invalid
    end
  end
end
