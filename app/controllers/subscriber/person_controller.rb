# encoding: UTF-8
module Subscriber
  class PersonController < BaseController

    skip_authorize_resource # must be in leaf class
    
    before_render_form :replace_validation_errors

    private
    
    def subscriber
      Person.find(subscriber_id)
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
