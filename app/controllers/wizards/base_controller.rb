module Wizards
  class BaseController < ApplicationController
    helper_method :entry

    def new; end

    def create
      return render :new if params[:autosubmit].present?
      return save_and_redirect if entry.valid? && entry.last_step?

      entry.move_on
      render :new
    end

    private

    def save_and_redirect
      save_entry
      redirect_to redirect_target, notice: success_message
    end

    def save_entry
      ApplicationRecord.transaction do
        entry.save!
      end
    end

    def entry
      @entry ||= model_class.new(
        current_ability:,
        params: model_params.to_unsafe_h,
        current_step: params[:step]
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
