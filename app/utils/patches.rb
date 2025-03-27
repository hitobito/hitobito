module Patches
  GEM_HOME = ENV["GEM_HOME"] # rubocop:disable Rails/EnvironmentVariableAccess

  RAILS_ROOT = Rails.root
  DEV_ROOT = RAILS_ROOT.parent
  PATCHES_DIR = RAILS_ROOT.join(".patches")
  CORE_APP_DIR = RAILS_ROOT.join("app")
  WAGON_REGEX = %r{/hitobito_(\w+)}

  Patch = Data.define(:method, :file, :line, :wagon) do
    def location = Pathname(file).relative_path_from(DEV_ROOT).to_s

    def info = {method:, location:}
  end

  Klass = Data.define(:name, :file, :patches) do
    def analyze = Analyzer.new.analyze(self)

    def patched? = patches.any?

    def location = Pathname(file).relative_path_from(DEV_ROOT).to_s

    def wagons = patches.map(&:wagon).uniq

    def info(wagon = wagons.first)
      {location => {name:, patches: patch_infos(wagon)}}
    end

    def patch_infos(wagon) = patches.select { |patch| patch.wagon == wagon }.map(&:info)
  end

  class Collector
    attr_reader :patch_files

    def initialize
      @patch_files = Hash.new { |h, k| h[k] = File.open(PATCHES_DIR.join("#{k}.yml"), "w") }
    end

    def collect
      each_zeitwerk_class.map do |name, location|
        Klass.new(name, location, []).tap(&:analyze)
      end.compact.sort_by(&:name)
    end

    def patched_klasses = collect.select(&:patched?)

    def wagons = patched_klasses.map(&:wagons).flatten.uniq

    def write
      FileUtils.mkdir_p(PATCHES_DIR) unless PATCHES_DIR.exist?

      wagons.each do |wagon|
        infos = patched_klasses.map { |klass| klass.info(wagon) }
        puts "writing patches for #{wagon}" # rubocop:disable Rails/Output
        patch_files[wagon].puts(infos.to_yaml)
        patch_files[wagon].close
      end
    end

    private

    # Maybe good enough, maybe not ..
    def each_zeitwerk_class
      Rails.autoloaders.main.instance_variable_get(:@to_unload).map do |location, cref|
        next if location.starts_with?(GEM_HOME) || !location.ends_with?(".rb")
        constant = cref.mod.const_get(cref.cname.to_s)
        next unless constant.is_a?(Class)
        [constant.to_s, location]
      end.compact
    end
  end

  class Analyzer
    def analyze(klass)
      constant = klass.name.constantize
      constant.instance_methods(false).each do |method|
        file, line = constant.instance_method(method).source_location
        next if irrelevant?(file)
        klass.patches << Patch.new(method, file, line, extract_wagon(file))
      end
    end

    def irrelevant?(file)
      file.starts_with?(GEM_HOME) || file.starts_with?(CORE_APP_DIR.to_s)
    end

    def extract_wagon(file) = file[WAGON_REGEX, 1]
  end
end
