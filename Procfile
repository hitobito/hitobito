web: bundle exec rails s -b 0.0.0.0 -p 3000
worker: bundle exec rake jobs:work
mail: mailcatcher -f --smtp-port 2025
webpack: bundle exec bin/webpack-dev-server
migrate: echo "Migrating core" && bundle exec rails db:migrate && echo "Migrating wagons" && bundle exec rails wagon:migrate
