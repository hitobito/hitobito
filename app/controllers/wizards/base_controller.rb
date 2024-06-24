module Wizards
  class BaseController < ApplicationController
    helper_method :wizard

    def new; end

    def create
      return render :new if params[:autosubmit].present?
      return save_and_redirect if wizard.valid? && wizard.last_step?


      wizard.move_on
      render :new, status: :unprocessable_entity # to make it work with turbo
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
        current_ability:,
        current_step: params[:step],
        **model_params.to_unsafe_h,
      )
    end

    def model_params
      params[model_identifier] || ActionController::Parameters.new
    end

    def model_identifier
      @model_identifier ||= model_class.model_name.param_key
    end

    def model_class
      raise 'Implement in subclass'
    end

    def success_message
      raise 'Implement in subclass'
    end

    def redirect_target
      raise 'Implement in subclass'
    end

  end
end
