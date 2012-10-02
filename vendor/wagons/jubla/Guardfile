# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# we need to remove the vendor directory from the ignored paths
ignores = ::Guard.listener.directory_record.instance_variable_get("@ignoring_patterns")
ignores.delete_if {|e| e.to_s.include?('vendor') }
ignores << /^(?:\.rbx|\.bundle|\.git|\.svn|log|tmp)\//

# the directory of the current wagon
wagons_dir = "vendor#{File::SEPARATOR}wagons#{File::SEPARATOR}"
wagon = wagons_dir + File.dirname(__FILE__).split(wagons_dir).last


notification :off

guard 'spork', :cucumber_env => { 'RAILS_ENV' => 'test' }, :rspec_env => { 'RAILS_ENV' => 'test' }, :rspec_port => 8991 do
  watch('config/application.rb')
  watch('config/environment.rb')
  watch(%r{^config/environments/.+\.rb$})
  watch(%r{^config/initializers/.+\.rb$})
  watch('Gemfile')
  watch('Gemfile.lock')
  watch('spec/spec_helper.rb')
  watch('#{wagon}/spec/spec_helper.rb')
  watch(%r{^spec/support/.+\.rb$})
  watch(%r{^#{wagon}/spec/support/.+\.rb$})
  watch(%r{^app/models/.+\.rb$})
  watch(%r{^#{wagon}/app/models/.+\.rb$})
  watch(%r{^app/controllers/.+\.rb$})
  watch(%r{^#{wagon}/app/controllers/.+\.rb$})
end

guard 'rspec', :version => 2, :cli => '--drb --drb-port 8991' do
  watch(%r{^.*\.rb$}) {|m| puts m }

  watch(%r{^#{wagon}/(spec/.+_spec\.rb)$}) { |m| m[1] }
  watch(%r{^lib/(.+)\.rb$})              { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')           { "spec" }
  watch('#{wagon}/spec/spec_helper.rb')  { "spec" }

  # Rails example
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^#{wagon}/app/(.+)\.rb$})                  { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^#{wagon}/app/models/jubla/(.+)\.rb$})     { |m| "spec/models/#{m[1]}_spec.rb" }
  watch(%r{^#{wagon}/app/models/group/(.+)\.rb$})     { |m| "spec/models/group_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml)$})                 { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^#{wagon}/app/(.*)(\.erb|\.haml)$})        { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
  watch(%r{^#{wagon}/app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
  watch(%r{^#{wagon}/spec/support/(.+)\.rb$})         { "spec" }
  #watch('config/routes.rb')                           { "spec/routing" }
  #watch('#{wagon}/config/routes.rb')                  { "spec/routing" }
  watch('app/controllers/application_controller.rb')  { "spec/controllers" }
  
  # Capybara request specs
  watch(%r{^app/views/(.+)/.*\.(erb|haml)$})          { |m| "spec/requests/#{m[1]}_spec.rb" }
  
  # Turnip features and steps
  watch(%r{^spec/acceptance/(.+)\.feature$})
  watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$})   { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance' }
  
end

