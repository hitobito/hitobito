module Patches
  RUBY_HOME = Pathname(ENV["GEM_HOME"]).parent.parent.to_s # rubocop:disable Rails/EnvironmentVariableAccess
  RAILS_ROOT = Rails.root
  DEV_ROOT = RAILS_ROOT.parent
  PATCHES_DIR = RAILS_ROOT.join(".patches")
  CORE_APP_DIR = RAILS_ROOT.join("app")
  WAGON_REGEX = %r{/hitobito_(\w+)}

  Patch = Data.define(:method, :file, :line, :wagon) do
    def location = Pathname(file).relative_path_from(DEV_ROOT).to_s

    def info = {method:, location:, line:, wagon:}
  end

  class Klass
    attr_reader :name, :file, :patches

    def initialize(name, file)
      @name = name
      @file = file
    end

    def analyze
      @patches = Analyzer.new(name.constantize).patches
    end

    def patched? = patches.any?

    def location = Pathname(file).relative_path_from(DEV_ROOT).to_s

    def wagons = patches.map(&:wagon).uniq

    def info(wagon = wagons.first)
      [location, {name:, patches: patch_infos(wagon)}]
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
        Klass.new(name, location).tap(&:analyze)
      end.compact.sort_by(&:name)
    end

    def write
      FileUtils.mkdir_p(PATCHES_DIR) unless PATCHES_DIR.exist?

      binding.pry
      write_wagons
      write_main
    end

    private

    def patched_klasses = collect.select(&:patched?)

    def wagons = patched_klasses.map(&:wagons).flatten.uniq

    def write_wagons
      wagons.each do |wagon|
        infos = patched_klasses.map { |klass| klass.info(wagon) }.to_h
        puts "writing patches for #{wagon}" # rubocop:disable Rails/Output
        patch_files[wagon].puts(infos.to_yaml)
        patch_files[wagon].close
      end
    end

    def write_main
      patches = PATCHES_DIR
        .glob("*.yml")
        .map { |file| file.read }
        .inject({}) { |memo, file| memo.deep_merge(YAML.load(file.read)) }

      PATCHES_DIR.join("patches.yml").write(patches)
    end

    # Maybe good enough, maybe not ..
    def each_zeitwerk_class
      Rails.autoloaders.main.instance_variable_get(:@to_unload).map do |location, cref|
        next if location.starts_with?(RUBY_HOME) || !location.ends_with?(".rb")
        constant = cref.mod.const_get(cref.cname.to_s)
        next unless constant.is_a?(Class)
        [constant.to_s, location]
      end.compact
    end
  end

  class Analyzer
    attr_reader :constant

    def initialize(constant)
      @constant = constant
    end

    def patches
      patches = direct_patches
      (patches + ancestor_patches(patches.map(&:method))).uniq # ancestors produce duplicates
    end

    def direct_patches
      methods(constant).map do |method|
        file, line = constant.instance_method(method).source_location
        next if irrelevant_path?(file)
        Patch.new(method, file, line, extract_wagon(file))
      end.compact
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
          Patch.new(method, file, line, extract_wagon(file))
        end
      end.compact
    end

    def irrelevant_ancestor?(ancestor)
      ancestor == constant || ancestor == Object || ancestor == Kernel || ancestor == BasicObject
    end

    def irrelevant_path?(file)
      file.starts_with?(RUBY_HOME) || file.starts_with?(CORE_APP_DIR.to_s)
    end

    def extract_wagon(file) = file[WAGON_REGEX, 1]
  end
end
