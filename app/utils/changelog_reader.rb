class ChangelogReader
  class << self
    def get_changelog()
      changelogs = {}
      version = ''
      file = File.read('CHANGELOG.md')

      file.each_line do |l|
        l.gsub!("\n",'')

        if l.include? "##"
          l.gsub!('## ', '')
          version = l
          changelogs[version] = []
        elsif l.include? "*"
          changelogs[version] << l
          l.gsub!('* ', '')
        end
      end
      changelogs
    end
  end
end
