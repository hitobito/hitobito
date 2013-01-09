# encoding: UTF-8
module Subscriber
  class PersonController < BaseController

    before_render_form :replace_validation_errors

    private

    def assign_attributes
      if model_params && model_params[:subscriber_id].present?
        entry.subscriber = Person.find(model_params[:subscriber_id])
      end
    end

    def replace_validation_errors
      if entry.errors[:subscriber_type].present?
        entry.errors.clear
        entry.errors.add(:base, 'Person muss ausgewählt werden')
      end

      if entry.errors[:subscriber_id].present?
        entry.errors.clear
        entry.errors.add(:base, 'Person wurde bereits hinzugefügt')
      end
    end
  end
end
