
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

begin
  require 'rubocop/rake_task'

  desc 'Run RuboCop '
  Rubocop::RakeTask.new(:rubocop) do |task|
    # don't abort rake on failure
    task.fail_on_error = false
  end
rescue LoadError
  # no rubocop available, no problem
end