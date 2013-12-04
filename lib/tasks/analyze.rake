
desc "Run brakeman"
task :brakeman do
  FileUtils.rm_f('brakeman-output.tabs')
  # some files seem to cause brakeman to hang. ignore them
  ignores = %w(app/views/people_filters/_form.html.haml
               app/views/csv_imports/define_mapping.html.haml
               app/models/mailing_list.rb)
  begin
    Timeout.timeout(300) do
      sh "brakeman -o brakeman-output.tabs --skip-files #{ignores.join(',')} --no-progress"
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
  desc 'Run rubocop-reports.yml and generate report'
  task :report do
    # do not fail if we find issues
    sh %w(rubocop
          --config rubocop-report.yml
          --require rubocop/formatter/checkstyle_formatter
          --format Rubocop::Formatter::CheckstyleFormatter
          --no-color
          --rails
          --out tmp/rubocop.xml).join(' ') rescue nil
    true
  end
end