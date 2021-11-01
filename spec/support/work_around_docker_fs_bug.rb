# Workaround for https://github.com/docker/for-linux/issues/1015,
# solution from https://github.com/docker/for-linux/issues/1015#issuecomment-860072969
#
# TODO remove once that's fixed

require 'fileutils'

module FileUtils
  class Entry_
    def copy_file(dest)
      File.open(path()) do |s|
        File.open(dest, 'wb', s.stat.mode) do |f|
          s.chmod s.lstat.mode
          IO.copy_stream(s, f)
        end
      end
    end
  end
end
