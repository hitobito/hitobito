# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Patches
  RUBY_HOME = Pathname(Gem::RUBYGEMS_DIR).parent.parent.to_s
  RAILS_ROOT = Pathname.new(File.expand_path("../../../", __FILE__))
  PATCHES_DIR = RAILS_ROOT.join(".patches")
  ALL_PATCHES = RAILS_ROOT.join(".patches.yml")
  DEV_ROOT = RAILS_ROOT.parent
  CORE_APP_DIR = RAILS_ROOT.join("app")
  WAGON_REGEX = %r{/.*hitobito_(\w+).*}

  Repo = Data.define(:name) do
    REGEX = %r{^hitobito_(\w+)$} # rubocop:disable Lint/ConstantDefinitionInBlock

    def wagon = REGEX.match(name)[1]

    def wagon? = REGEX.match(name)

    def patches_uri
      URI.parse("https://raw.githubusercontent.com/hitobito/#{name}/refs/heads/master/.patches.yml")
    end

    def download_patches
      response = Net::HTTP.get_response(patches_uri)
      return unless response.code.to_i == 200

      file = RAILS_ROOT.join(".patches/#{wagon}.yml")
      Rails.root.join(file).write(response.body)
    end
  end

  class Collector
    REPO_QUERY_LIMIT = 100 # defaults to 30 which excludes some wagons

    def write
      Dir.mkdir(PATCHES_DIR) unless PATCHES_DIR.exist?

      download_wagon_patches
      consolidate
    end

    private

    def download_wagon_patches
      repos.each(&:download_patches)
    end

    def consolidate
      patches = PATCHES_DIR.glob("*.yml").map { |file| YAML.load(file.read) }.flatten.compact
      ALL_PATCHES.write(patches.flatten.to_yaml)
    end

    def repos
      shell_out("gh repo list hitobito -L #{REPO_QUERY_LIMIT} --no-archived --json name")
        .then { |json| JSON.parse(json) }
        .map { |attrs| Repo.new(**attrs) }
        .select(&:wagon?)
    end

    def shell_out(command, dry_run: false)
      stdout, _stderr, status = Open3.capture3(*command)
      raise "Command failed: #{command}" unless status.success?
      stdout
    end
  end

  Patch = Data.define(:method, :constant, :wagon, :source_file, :patch_file, :patch_file_line) do
    include Comparable
    def basename = Pathname.new(source_file).basename.to_s

    def <=>(other)
      if constant == other.constant
        method <=> other.method
      else
        constant <=> other.constant
      end
    end
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

  class Generator
    PATCH_FILE = Pathname.new(Dir.pwd).join(".patches.yml")

    def collect
      each_zeitwerk_class.map do |name, location|
        Klass.new(name, location).tap(&:analyze)
      end.compact.sort_by(&:name)
    end

    def write
      patches = collect.select(&:patched?).flat_map(&:patches).sort.map(&:to_h)
      puts "Writing to #{PATCH_FILE}" # rubocop:disable Rails/Output
      File.write(PATCH_FILE, patches.to_yaml)
    end

    private

    # Maybe good enough, maybe not ..
    def each_zeitwerk_class # rubocop:todo Metrics/CyclomaticComplexity
      load_and_adjust_zeitwerk_classes.map do |constant, (location, cref)|
        next if location.starts_with?(RUBY_HOME) || !location.ends_with?(".rb")
        next if %r{/gems/}.match?(location)
        next unless constant.constantize.is_a?(Class)
        next if constant.constantize.superclass == Object
        [constant, location]
      end.compact
    end

    # on CI we dont have the constant as key so we take it form the cref
    def load_and_adjust_zeitwerk_classes
      Rails.autoloaders.main.instance_variable_get(:@to_unload).map do |key, value|
        case value
        when Zeitwerk::Cref then [value.path.constantize.to_s, [key, value]]
        when Array then [value.last.path.constantize.to_s, [value.first, value.last]]
        end
      end.to_h
    end
  end

  class Analyzer
    # TODO
    # this is needs a reality check and cannot be considered final yet

    attr_reader :constant, :source_file

    def initialize(constant, source_file = nil)
      @constant = constant
      @source_file = source_file
    end

    def patches
      ancestor_patches(direct_patches.map(&:method)).uniq # ancestors produce duplicates
    end

    def direct_patches # rubocop:todo Metrics/AbcSize
      patched_methods = methods(constant) & (ancestors.flat_map { |ancestor| methods(ancestor) })
      patched_methods.map do |method|
        file, line = constant.instance_method(method).source_location
        next if irrelevant_path?(file, source_file)

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
          next if irrelevant_path?(file, source_file)
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
      # rubocop:todo Layout/LineLength
      ancestor == constant || ancestor == Data || ancestor == Object || ancestor == Kernel || ancestor == BasicObject
      # rubocop:enable Layout/LineLength
    end

    def irrelevant_path?(file, source_file)
      # rubocop:todo Layout/LineLength
      file.nil? || file.starts_with?(RUBY_HOME) || file.starts_with?(CORE_APP_DIR.to_s) || !source_file.starts_with?(CORE_APP_DIR.to_s) ||
        # rubocop:enable Layout/LineLength
        %r{gems}.match?(file) # this seems to occur on CI
    end

    def extract_wagon(file) = file[WAGON_REGEX, 1]
  end
end
