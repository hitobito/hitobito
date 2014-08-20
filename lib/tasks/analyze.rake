# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

desc "Run brakeman"
task :brakeman do
  FileUtils.rm_f('brakeman-output.tabs')
  # some files seem to cause brakeman to hang. ignore them
  ignores = %w(app/views/people_filters/_form.html.haml
               app/views/csv_imports/define_mapping.html.haml
               app/models/mailing_list.rb
               app/controllers/full_text_controller.rb)

  begin
    Timeout.timeout(300) do
      sh %W(brakeman -o brakeman-output.tabs
                     --skip-files #{ignores.join(',')}
                     -x ModelAttrAccessible
                     -q
                     --no-progress).join(' ')
    end
  rescue Timeout::Error => e
    puts "\nBrakeman took too long. Aborting."
  end
end

desc "Run quality analysis"
task :qa do
  # do not fail if we find issues
  sh 'rails_best_practices -x config,db -f html --vendor .' rescue nil
  true
end


desc 'Run rubocop-must.yml and fail if there are issues'
task :rubocop do
  begin
    sh "rubocop --config rubocop-must.yml"
  rescue
    abort('RuboCop failed!')
  end
end

namespace :rubocop do
  desc 'Run .rubocop.yml and generate checkstyle report'
  task :report do
    # do not fail if we find issues
    sh %w(rubocop
          --require rubocop/formatter/checkstyle_formatter
          --format RuboCop::Formatter::CheckstyleFormatter
          --no-color
          --out rubocop-results.xml).join(' ') rescue nil
    true
  end
end
