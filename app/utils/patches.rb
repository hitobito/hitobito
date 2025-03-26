module Patches
  class SourceDirectory
    attr_reader :path

    def initialize(path)
      @path = File.expand_path(path)
    end

    def contains?(file_path)
      file_path&.start_with?(path)
    end

    def to_s
      "SourceDirectory: #{path}"
    end
  end

  class MethodInfo
    attr_reader :name, :source_file, :klass_name, :superclass_name

    def initialize(name, source_file, klass_name, superclass_name = nil)
      @name = name
      @source_file = source_file
      @klass_name = klass_name
      @superclass_name = superclass_name
    end

    def to_h
      {
        source: Module.const_source_location(klass_name),
        patch: source_file,
        name: name
      }
    end

    def to_s
      "Method: #{name}, Class: #{klass_name}, Superclass: #{superclass_name || "None"}"
    end
  end

  class ClassMethodAnalyzer
    def initialize(klass, wagon_directories)
      @klass = klass
      @wagon_directories = wagon_directories.map { |dir| SourceDirectory.new(dir) }
    end

    def analyze
      added_methods = {}
      overridden_methods = {}
      analyze_methods_for_class(added_methods, overridden_methods)
      {added_methods: added_methods, overridden_methods: overridden_methods}
    end

    private

    def analyze_methods_for_class(added_methods, overridden_methods)
      superclass = @klass.superclass
      return if superclass.nil?

      @klass.instance_methods(false).each do |method_name|
        source_file = get_method_source_file(method_name)
        next if source_file.starts_with?(ENV["GEM_HOME"]) # rubocop:disable Rails/EnvironmentVariableAccess
        next unless @wagon_directories.any? { |dir| dir.contains?(source_file) }

        if superclass.instance_methods.include?(method_name)
          overridden_methods[method_name] = MethodInfo.new(method_name, source_file, @klass.name, superclass.name)
        else
          added_methods[method_name] = MethodInfo.new(method_name, source_file, @klass.name)
        end
      end
      analyze_overridden_methods_in_ancestors(added_methods, overridden_methods)
    end

    def analyze_overridden_methods_in_ancestors(added_methods, overridden_methods)
      @klass.ancestors.each do |ancestor|
        next if ancestor == @klass || ancestor == Object || ancestor == Kernel || ancestor == BasicObject

        ancestor.instance_methods.each do |method_name|
          next unless @klass.instance_methods(false).include?(method_name) && !overridden_methods.key?(method_name)

          source_file = get_method_source_file(method_name)
          next unless @wagon_directories.any? { |dir| dir.contains?(source_file) }
          overridden_methods[method_name] = MethodInfo.new(method_name, source_file, @klass.name, ancestor.name)
        end
      end
    end

    def get_method_source_file(method_name)
      method_obj = @klass.instance_method(method_name)
      source_file, _ = method_obj.source_location
      source_file
    rescue TypeError, NameError
      nil
    end
  end

  class Runner
    attr_reader :added_methods, :overridden_methods, :origin_directories, :wagon_directories

    def initialize
      @added_methods = []
      @overridden_methods = []
      @origin_directories = [Rails.root.to_s]
      @wagon_directories = Wagons.all.map(&:root)
      collect_patches
    end

    def collect_patches
      classes_to_analyze = find_classes_in_origin_and_wagon(origin_directories, wagon_directories)

      classes_to_analyze.each do |klass|
        analyzer = ClassMethodAnalyzer.new(klass, wagon_directories)
        result = analyzer.analyze
        @added_methods += result[:added_methods].values
        @overridden_methods += result[:overridden_methods].values
      end
    end

    def find_classes_in_origin_and_wagon(origin_directories, wagon_directories)
      origin_source_dirs = origin_directories.map { |dir| SourceDirectory.new(dir) }
      wagon_source_dirs = wagon_directories.map { |dir| SourceDirectory.new(dir) }

      ObjectSpace.each_object(Class).select do |klass|
        klass.instance_methods.any? do |method_name|
          method_in_origin_and_wagon?(klass, method_name, origin_source_dirs, wagon_source_dirs)
        end
      end
    end

    def method_in_origin_and_wagon?(klass, method_name, origin_source_dirs, wagon_source_dirs)
      begin
        method_obj = klass.instance_method(method_name)
        source_file, _ = method_obj.source_location
      rescue TypeError, NameError
        return false
      end

      return false unless source_file

      origin_match = origin_source_dirs.any? { |dir| dir.contains?(source_file) }
      wagon_match = wagon_source_dirs.any? { |dir| dir.contains?(source_file) }
      origin_match && wagon_match
    end

    # rubocop:disable Rails/Output
    def write_patches
      puts "Added Methods:"
      added_methods.each do |klass, methods|
        puts "  Class: #{klass.name}"
        methods.each do |method_name, method_info|
          puts "    #{method_info}" # Uses the to_s method in MethodInfo
        end
      end

      puts "\nOverridden Methods:"
      overridden_methods.each do |klass, methods|
        puts "  Class: #{klass.name}"
        methods.each do |method_name, method_info|
          puts "    #{method_info}"
        end
      end
      # rubocop:enable Rails/Output
    end
  end
end
