# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Wizards
  class BaseController < ApplicationController
    helper_method :wizard

    def create
      return render :show if params[:autosubmit].present?
      return save_and_redirect if wizard.valid? && wizard.last_step?

      wizard.move_on
      render :show, status: :unprocessable_entity # required for turbo to update
    end

    private

    def save_and_redirect
      save_wizard
      redirect_to redirect_target, notice: success_message
    end

    def save_wizard
      ApplicationRecord.transaction do
        wizard.save!
      end
    end

    def wizard
      @wizard ||= model_class.new(
        current_ability: current_ability,
        current_step: params[:step],
        **model_params.to_unsafe_h
      )
    end

    def model_params
      params[model_identifier] || ActionController::Parameters.new
    end

    def model_identifier
      @model_identifier ||= model_class.model_name.param_key
    end

    def model_class
      raise "Implement in subclass"
    end

    def success_message
      raise "Implement in subclass"
    end

    def redirect_target
      raise "Implement in subclass"
    end
  end
end
