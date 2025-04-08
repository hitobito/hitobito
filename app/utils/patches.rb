# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito_swb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_swb.

module Patches
  RUBY_HOME = Pathname(ENV["GEM_HOME"]).parent.parent.to_s # rubocop:disable Rails/EnvironmentVariableAccess
  RAILS_ROOT = Pathname.new(File.expand_path("../../../", __FILE__))
  DEV_ROOT = RAILS_ROOT.parent
  PATCHES_DIR = RAILS_ROOT.join(".patches")
  ALL_PATCHES = PATCHES_DIR.join("all.yml")
  CORE_APP_DIR = RAILS_ROOT.join("app")
  WAGON_REGEX = %r{/hitobito_(\w+)}

  Patch = Data.define(:method, :constant, :wagon, :source_file, :patch_file, :patch_file_line) do
    def basename = Pathname.new(source_file).basename.to_s
  end

  class Klass
    attr_reader :name, :file, :patches

    def initialize(name, file)
      @name = name
      @file = file
    end

    def analyze
      @patches = Analyzer.new(name.constantize, file).patches
    end

    def patched? = patches.any?

    def location = Pathname(file).relative_path_from(DEV_ROOT).to_s

    def wagons = patches.map(&:wagon).uniq
  end

  class Collector
    attr_reader :patch_files

    def initialize
      @patch_files = Hash.new { |h, k| h[k] = File.open(PATCHES_DIR.join("#{k}.yml"), "w") }
    end

    def collect
      each_zeitwerk_class.map do |name, location|
        Klass.new(name, location).tap(&:analyze)
      end.compact.sort_by(&:name)
    end

    def write
      FileUtils.mkdir_p(PATCHES_DIR) unless PATCHES_DIR.exist?

      write_wagons
      write_main
    end

    private

    def patched_klasses = collect.select(&:patched?)

    def wagons = patched_klasses.map(&:wagons).flatten.uniq

    def write_wagons
      wagons.each do |wagon|
        infos = patched_klasses
          .flat_map(&:patches)
          .select { |patch| patch.wagon == wagon }
          .map(&:to_h)
        puts "writing patches for #{wagon}" # rubocop:disable Rails/Output
        patch_files[wagon].puts(infos.to_yaml)
        patch_files[wagon].close
      end
    end

    def write_main
      patches = PATCHES_DIR
        .glob("*.yml")
        .map { |file| YAML.load(file.read) }

      ALL_PATCHES.write(patches.flatten.to_yaml)
    end

    # Maybe good enough, maybe not ..
    def each_zeitwerk_class
      Rails.autoloaders.main.instance_variable_get(:@to_unload).map do |constant, (location, cref)|
        next if location.starts_with?(RUBY_HOME) || !location.ends_with?(".rb")
        next unless constant.constantize.is_a?(Class)
        next if constant.constantize.superclass == Object
        [constant, location]
      end.compact
    end
  end

  class Analyzer
    attr_reader :constant, :source_file

    def initialize(constant, source_file = nil)
      @constant = constant
      @source_file = source_file
    end

    def patches
      patches = direct_patches
      (patches + ancestor_patches(patches.map(&:method))).uniq # ancestors produce duplicates
    end

    ## TODO
    # - generates too much if a module in ancestor change uses delegate class methods
    def direct_patches
      patched_methods = methods(constant) & (ancestors.flat_map { |ancestor| methods(ancestor) })
      patched_methods.map do |method|
        file, line = constant.instance_method(method).source_location
        next if irrelevant_path?(file)

        Patch.new(
          method: method,
          constant: constant.to_s,
          wagon: extract_wagon(file),
          source_file: relative_path(method_source_file(method)),
          patch_file: relative_path(file),
          patch_file_line: line
        )
      end.compact
    end

    def method_source_file(method)
      ancestor = ancestors.find { |a| methods(a).include?(method) }
      ancestor ? ancestor.instance_method(method).source_location[0] : source_fil
    end

    def ancestors
      constant.ancestors.reject { |ancestor| irrelevant_ancestor?(ancestor) }
    end

    def methods(source = constant)
      source.public_instance_methods(false) + source.private_instance_methods(false)
    end

    def ancestor_patches(methods)
      methods.flat_map do |method|
        ancestors.map do |ancestor|
          next if methods(ancestor).exclude?(method)
          file, line = ancestor.instance_method(method).source_location
          next if irrelevant_path?(file)
          Patch.new(
            method: method,
            constant: constant.to_s,
            wagon: extract_wagon(file),
            source_file: relative_path(source_file),
            patch_file: relative_path(file),
            patch_file_line: line
          )
        end
      end.compact
    end

    def relative_path(file) = Pathname(file).relative_path_from(DEV_ROOT).to_s

    def irrelevant_ancestor?(ancestor)
      ancestor == constant || ancestor == Data || ancestor == Object || ancestor == Kernel || ancestor == BasicObject
    end

    def irrelevant_path?(file)
      file.nil? || file.starts_with?(RUBY_HOME) || file.starts_with?(CORE_APP_DIR.to_s)
    end

    def extract_wagon(file) = file[WAGON_REGEX, 1]
  end
end
