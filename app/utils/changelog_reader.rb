class ChangelogReader
  class << self
    def get_changelog()
      @changelogs = {}
      @version = ''

      write_core_changes
      write_wagon_changes

      @changelogs
    end

private
    def write_changes(file)
      file.each_line do |l|
        l.gsub!("\n",'')
        if l.include? "##"
          l.gsub!('## ', '')
          @version = l
        elsif l.include? "*"
          l.gsub!('* ', '')
          @changelogs[@version] << l
        end
      end
    end

    def write_core_changes
      core_file = File.read('CHANGELOG.md')
      create_versions(core_file)
      write_changes(core_file)
    end

    def create_versions(core_file)
      core_file.each_line do |l|
        l.gsub!("\n",'')
        if l.include? "##"
          l.gsub!('## ', '')
          @changelogs[l] = []
        end
      end
    end

    def write_wagon_changes
      Wagons.all.each do |w|
        file_location = "#{w.root}/CHANGELOG.md"
        if File.exists?(file_location)
          file = File.read(file_location)
          write_changes(file)
        end
      end
    end
  end
end
