# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Group::Statistics::Registry
  class_attribute :statistics, default: []

  class << self
    # Registration of statistic classes
    # Each statistic class must implement the class methods .key and .available_for?(group)
    # Additional statistics can be registered in wagons in `wagon.rb`:
    #
    #    config.to_prepare do
    #      Group::Statistics::Registry.register(MyCustomStatistic)
    def register(*stat_classes)
      stat_classes.each do |stat_class|
        validate_interface!(stat_class)
        statistics << stat_class unless statistics.include?(stat_class)
      end
    end

    def available_for(group)
      statistics.select { |stat| stat.available_for?(group) }
    end

    def find_by_key(key)
      statistics.find { |stat| stat.key == key.to_sym }
    end

    private

    # Validates that the class implements the required interface
    def validate_interface!(stat_class)
      unless stat_class.respond_to?(:key) && stat_class.key.present?
        raise "#{stat_class} must define class_attribute :key"
      end

      unless stat_class.respond_to?(:available_for?)
        raise "#{stat_class} must implement .available_for?"
      end
    end
  end

  # Registration of core statistics.
  # Additional statistics can be registered in wagons in `wagon.rb`
  register(Group::Statistics::Demographic)
end
