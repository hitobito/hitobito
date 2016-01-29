# encoding: utf-8

class ChangelogReader
  class << self
    def changelog
      @changelogs = {}
      @version = ''

      add_core_changes
      add_wagon_changes

      @changelogs
    end

private
    def add_changes(file)
      file.each_line do |l|
        l.delete! "\n"
        add_line(l)
      end
    end

    def add_line(l)
      if l.include? "##"
        l.delete! '#'
        @version = l
      elsif l.include? "*"
        l.delete! '*'
        @changelogs[@version] << l
      end
    end

    def add_core_changes
      core_file = File.read('CHANGELOG.md')
      create_versions(core_file)
      add_changes(core_file)
    end

    def create_versions(core_file)
      core_file.each_line do |l|
        l.delete! "\n"
        if l.include? "##"
          l.delete! '#'
          @changelogs[l] = []
        end
      end
    end

    def add_wagon_changes
      Wagons.all.each do |w|
        file_location = "#{w.root}/CHANGELOG.md"
        if File.exist?(file_location)
          file = File.read(file_location)
          add_changes(file)
        end
      end
    end
  end
end
