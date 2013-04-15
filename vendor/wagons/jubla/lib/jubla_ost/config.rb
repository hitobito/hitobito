module JublaOst
  class Config
    class << self
      def database
        config['database']
      end

      def kanton_id(shortname)
        config['kanton'][shortname.downcase] || raise("No canton '#{shortname}' found")
      end

      def config
        @config ||= YAML.load_file(File.join(File.dirname(__FILE__), 'config.yml'))
      end
    end
  end
end