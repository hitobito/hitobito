desc "Add column annotations to active records"
task :annotate do
  sh 'annotate -p before'
end

namespace :erd do
  task :options => :customize
  task :customize do
    ENV['attributes']  ||= 'content,inheritance,foreign_keys,timestamps'
    ENV['indirect']    ||= 'false'
    ENV['orientation'] ||= 'vertical'
    ENV['notation']    ||= 'uml'
    ENV['filename']    ||= 'doc/models'
    ENV['filetype']    ||= 'png'
  end
end
