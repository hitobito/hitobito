web: bundle exec rails server -b 0.0.0.0 -p 3000
worker: bundle exec rake jobs:work
mail: mailcatcher -f --smtp-port 2025
js: yarn build --watch
css: yarn build:css --watch
migrate: echo "Migrating core" && rails db:migrate && echo "Migrating wagons" && rails wagon:migrate
