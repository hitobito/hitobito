# encoding: UTF-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

class MapCountriesToTwoLetterCodes < ActiveRecord::Migration
  def up
    say_with_time('updating groups') do
      CountryMapper.new(Group).update
    end
    say_with_time('updating people') do
      CountryMapper.new(Person).update
    end
  end

  def down
  end

  class CountryMapper

    attr_reader :map, :model_class, :file

    LANGUAGES = %w(de fr it en)

    def initialize(model_class)
      @model_class = model_class
      @map = flipped_and_downcased(keyed_translations)
      @file = Rails.root.join("./log/#{model_class.to_s.downcase}_country_migration.log")
    end

    def update
      model_class.where("country != '' AND country is not null").find_each do |model|
        update_model(model)
      end

      changes.each do |country, ids|
        model_class.where(id: ids.to_a).update_all(country: country)
      end

      File.write(file, updates)
      changes.values.flatten.size
    end

    private

    def update_model(model)
      value = model.country

      if update_contactable(model, value)
        updates[:direct] << model.changes
      elsif update_contactable(model, mappings(value))
        updates[:mapped] << model.changes
      else
        updates[:failed] << model.country
      end

      if model.changed?
        changes[model.country] << model.id
      end
    end

    def update_contactable(model, value)
      value = value.to_s.downcase.strip
      if map[value]
        model.country = map[value]
      end
    end

    # hard coded mapping
    def mappings(country)
      case country.strip
      when "Amerika", "USA" then "US"
      when "Bolivien" then "BO"
      when "I - Italy" then "IT"
      when "Fürstentumlichtenstein" then "LI"
      when "Deutschalnd" then "DE"
      when "Espagna" then "ES"
      when "Suisss", "swiss", "Suisse/Schweiz", "Schwiiz", "Schwiz", "Schwiez", "Scheiz",
        "Scnweiz", "Scweiz", "Schnweiz", "Schweizz", "Schweit", "Sxhweiz", "Scnweiz",
        "Schwei", "Schweitz" "Schweizer", "Schweiu", "Schweo",
        "Schweiz (CH)", "Schweizer", "Schweitz",
        "Bern", "Berikon", "Lucerne", "Hettlingen", "St.Gallen", "Solothurn", "Luzern",
        "CH - Schweiz", "Schweiz CH", "Schweiz - CH", "CH (Schweiz)", "CH/IT",
        "Freiburg", "ZH", "Aargau", "Baselland" then "CH"
      when "f", "F" then "FR"
      when "Portugaise" then "PT"
      when "Republik Singapur" then "SG"
      when "TH - Thailand" then "TH"
      end
    end

    # returns country code map with translations, e.g. 'CH' => %w(Schweiz Suisse Switzerland)
    def keyed_translations
      ISO3166::Country::Translations.map do |key, value|
        translations = value.fetch('translations')
        names = translations.slice(*LANGUAGES).values
        [key, with_transliterate(names).to_a.compact] # compact because AN has no translations
      end
    end

    # adds "simplified" name, e.g. Oesterreich for Österreich
    def with_transliterate(names)
      names.inject(Set.new) do |set, val|
        set << val
        set << ActiveSupport::Inflector.transliterate(val) if val.present?
        set
      end
    end

    # flips and_downcases 'CH' => %w(Schweiz Suisse Switzerland) to { 'schweiz' => 'ch', 'suisse' => 'ch', ..}
    def flipped_and_downcased(data)
      data.each_with_object({}) do |(key, values), hash|
        hash[key.downcase] = key
        values.each { |val| hash[val.downcase] = key }
      end
    end

    def changes
      @changes ||= Hash.new { |k, v| k[v] = [] }
    end

    def updates
      @updates ||= Hash.new { |k, v| k[v] = Set.new }
    end
  end
end
