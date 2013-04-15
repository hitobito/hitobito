namespace :jublaost do

  task :migrate => :environment do
    Rails.application.config.autoload_paths << "#{JublaJubla::Wagon.root}/lib"

  end
end