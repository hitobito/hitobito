# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::Statistics::Registry
  class_attribute :statistics, default: []

  class << self
    # Registrierung von Statistik-Klassen
    # Jede Statistik-Klasse muss die Klasse-Methoden .key und .available_for?(group) implementieren
    # In Wagons können im `wagon.rb` weitere Statistiken registriert werden:
    #
    #    config.to_prepare do
    #      Group::Statistics::Registry.register(MyCustomStatistic)
    def register(*stat_classes)
      stat_classes.each do |stat_class|
        validate_interface!(stat_class)
        statistics << stat_class unless statistics.include?(stat_class)
      end
    end

    # Alle für eine Gruppe verfügbaren Statistiken
    def available_for(group)
      statistics.select { |stat| stat.available_for?(group) }
    end

    # Finde Statistik anhand des Keys
    def find_by_key(key)
      statistics.find { |stat| stat.key == key.to_sym }
    end

    private

    # Validiert dass die Klasse das erforderliche Interface implementiert
    def validate_interface!(stat_class)
      unless stat_class.respond_to?(:key) && stat_class.key.present?
        raise "#{stat_class} must define class_attribute :key"
      end

      unless stat_class.respond_to?(:available_for?)
        raise "#{stat_class} must implement .available_for?"
      end
    end
  end

  # Registrierung der Core Statistiken
  register(Group::Statistics::Demographic)
end
