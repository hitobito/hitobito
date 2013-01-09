# encoding: UTF-8
module Subscriber

  class BaseController < CrudController

    self.nesting = Group, MailingList

    decorates :group

    prepend_before_filter :parent

    def create
      super(location: group_mailing_list_subscriptions_path(@group, @mailing_list))
    end

    def authorize!(action, *args)
      super(:create, @subscription || @mailing_list.subscriptions.new)
    end

    private

    alias_method :mailing_list, :parent

    def replace_validation_errors
      default_base_errors.each do |key, value|
        if entry.errors[key].present?
          entry.errors.clear
          entry.errors.add(:base, value)
        end
      end
    end

    def default_base_errors
      { subscriber_type: "#{model_label} muss ausgewählt werden",
        subscriber_id: "#{model_label} wurde bereits hinzugefügt" }
    end

    class << self
      def model_class
        Subscription
      end
    end

  end
end
