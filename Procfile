web: bundle exec rails s -b 0.0.0.0 -p 3000
worker: bundle exec rake jobs:work
mail: mailcatcher -f --smtp-port 2025
js: bundle exec rake assets:watch_js
css: bundle exec rake assets:watch_css
migrate: echo "Migrating core" && bundle exec rails db:migrate && echo "Migrating wagons" && bundle exec rails wagon:migrate && echo "Tweak local dev-setup" && bundle exec rails delayed_job:clear dev:local:admin
