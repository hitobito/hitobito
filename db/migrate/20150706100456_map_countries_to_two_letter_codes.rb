# encoding: UTF-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

class MapCountriesToTwoLetterCodes < ActiveRecord::Migration[4.2]
  def up
    return if test_data?
    say_with_time('updating groups') do
      CountryMapper.new(Group).update_and_persist
    end
    say_with_time('updating people') do
      CountryMapper.new(Person).update_and_persist
    end
  end

  def down
  end

  private

  def test_data?
    Group.pluck(:type).any? { |type| type == 'Group::BottomLayer' }
  end

  class CountryMapper
    attr_reader :map, :changes, :failed, :log
    attr_reader :model_class, :file

    LANGUAGES = %w(de fr it en)

    def initialize(model_class)
      @map, @failed = {}, []
      @changes = Hash.new { |k, v| k[v] = [] }
      @log = Hash.new { |k, v| k[v] = Set.new }

      @model_class = model_class
      @file = Rails.root.join("./log/#{model_class.to_s.downcase}_country_migration.log")

      define(:BO, "Bolivien")
      define(:CH, ["Suisss", "swiss", "Suisse/Schweiz", "Schwiiz", "Schwiz", "Schwiez", "Scheiz",
                   "Scnweiz", "Scweiz", "Schnweiz", "Schweizz", "Schweit", "Sxhweiz", "Scnweiz",
                   "Schwei", "Schweitz" "Schweizer", "Schweiu", "Schweo",
                   "Schweiz (CH)", "Schweizer", "Schweitz",
                   "Bern", "Berikon", "Lucerne", "Hettlingen", "St.Gallen", "Solothurn", "Luzern",
                   "CH - Schweiz", "Schweiz CH", "Schweiz - CH", "CH (Schweiz)", "CH/IT",
                   "Freiburg", "ZH", "Aargau", "Baselland" ])
      define(:IT, "I - Italy")
      define(:LI, "Fürstentumlichtenstein")
      define(:DE, "Deutschalnd")
      define(:ES, "Espagna")
      define(:FR, "F")
      define(:PT, "Portugaise")
      define(:SG, "Republik Singapur")
      define(:TH, "TH - Thailand")
      define(:US, ["Amerika", "USA"])

      define_accepted_translations
    end

    def update_and_persist
      update
      persist
    end

    def update
      model_class.where('country IS NOT null').find_each do |model|
        value = model.country.strip.downcase

        if map[value]
          model.country = map[value]
          changes[model.country] << model.id
          log[:mapped] << model.changes['country'] if model.changed?
        else
          failed << model.id
          log[:failed] << model.country
        end
      end

      log
    end

    def persist
      changes.each do |country, ids|
        model_class.where(id: ids.to_a).update_all(country: country)
      end

      model_class.where(id: failed).update_all(country: nil)

      File.write(file, log)
      changes.values.flatten.size
    end

    private

    def define(key, args)
      Array(args).each { |value| map[value.downcase] = key.to_s }
    end

    def define_accepted_translations
      map.merge!(keyed_translations)
    end

    # returns country code map with translations, e.g. 'CH' => %w(Schweiz Suisse Switzerland)
    def keyed_translations
      hash = {}
      LANGUAGES.map do |lang|
        Countries.labels(lang).map do |key, value|
          hash[key.downcase] = key
          if value.present?
            hash[value.downcase] = key
            hash[ActiveSupport::Inflector.transliterate(value).downcase] = key
          end
        end
      end
      hash
    end
  end

end
