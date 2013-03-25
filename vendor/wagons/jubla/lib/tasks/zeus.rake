namespace :zeus do
  task :remove do
    rm "zeus.json"
    rm "config/boot.rb"
    rm "config/application.rb"
    rm "config/environment.rb"
    rm "config/environments"
  end
  task :add do
    sh "ln -s ../../../zeus.json"
    sh "ln -s ../../../../config/boot.rb config/boot.rb"
    sh "ln -s ../../../../config/application.rb config/application.rb"
    sh "ln -s ../../../../config/environment.rb config/environment.rb"
    sh "ln -s ../../../../config/environments config/environments"
  end
end