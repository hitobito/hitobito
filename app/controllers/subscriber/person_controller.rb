# encoding: UTF-8
module Subscriber
  class PersonController < BaseController

    before_render_form :replace_validation_errors

    private

    def assign_attributes
      if model_params && model_params[:subscriber_id].present?
        entry.subscriber = Person.find(model_params[:subscriber_id])
        entry.excluded = false
      end
    end

    def build_entry
      find_excluded_subscription || model_scope.new
    end

    def find_excluded_subscription
      if model_params && model_params[:subscriber_id].present?
        mailing_list.subscriptions.where(subscriber_id: model_params[:subscriber_id],
                                         subscriber_type: Person.sti_name, excluded: true).first
      end
    end

    def model_label
      Person.model_name.human
    end
  end
end
