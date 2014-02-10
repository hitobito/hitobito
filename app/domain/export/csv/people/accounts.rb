# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Csv::People
  class Accounts
    attr_reader :model

    class << self
      def phone_numbers
        @phone_numbers ||= new(PhoneNumber)
      end

      def social_accounts
        @social_accounts ||= new(SocialAccount)
      end
    end

    def initialize(model)
      @model = model
    end

    def key(label)
      "#{model.model_name.underscore}_#{label}".downcase.to_sym
    end

    def human(label)
      "#{model.model_name.human} #{label.capitalize}"
    end
  end
end
