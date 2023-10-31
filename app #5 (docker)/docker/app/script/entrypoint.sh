#!/bin/sh

# HACK: This is hack to keep assets in sync with nginx when container
#       is restarted with watchtower
cp -TR /app/public/ /app/public-shared/
bundle exec rake db:migrate
bundle exec puma -C config/puma/$RAILS_ENV.rb
