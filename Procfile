web: bundle exec rails s -b 0.0.0.0 -p 3000
worker: bundle exec rake jobs:work
mail: mailcatcher -f --smtp-port 2025
webpack: bin/webpack-dev-server
migrate: echo "Migrating core" && rails db:migrate && echo "Migrating wagons" && rails wagon:migrate
