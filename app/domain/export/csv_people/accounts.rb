module Export::CsvPeople
  class Accounts
    attr_reader :model

    class << self
      def phone_numbers
        @phone_numbers ||= self.new(PhoneNumber)
      end

      def social_accounts
        @social_accounts ||= self.new(SocialAccount)
      end
    end

    def initialize(model)
      @model = model
    end

    def key(label)
      "#{model.model_name.underscore}_#{label}".downcase.to_sym
    end

    def human(label)
      case model.model_name
      when "PhoneNumber" then "#{model.model_name.human} #{label.capitalize}"
      when "SocialAccount" then label.capitalize
      end
    end
  end
end