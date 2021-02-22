#  Copyright (c) 2012-2016, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

desc "Run brakeman"
task :brakeman do
  FileUtils.rm_f("brakeman-output.tabs")
  begin
    Timeout.timeout(300) do
      sh %w[brakeman -o brakeman-output.tabs -q --no-progress].join(" ")
    end
  rescue Timeout::Error
    puts "\nBrakeman took too long. Aborting."
  end
end

desc "Run rubocop-must.yml and fail if there are issues"
task :rubocop do
  sh "rubocop --config rubocop-must.yml"
rescue
  abort("RuboCop failed!")
end

namespace :rubocop do
  desc "Run .rubocop.yml and generate checkstyle report"
  task :report do
    # rubocop:disable Style/RescueModifier do not fail if we find issues
    sh %w[rubocop
          --require rubocop/formatter/checkstyle_formatter
          --format RuboCop::Formatter::CheckstyleFormatter
          --no-color
          --out rubocop-results.xml].join(" ") rescue nil
    # rubocop:enable Style/RescueModifier
    true
  end

  desc "Run .rubocop.yml on changed files"
  task :changed do
    sh "git ls-files -m -o -x spec -x test | grep '\\.rb$' | xargs rubocop"
  end
end
