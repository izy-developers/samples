FROM ghcr.io/izy-developers/dockerize:base

ARG COMPILE_STATIC=true
ARG SITEMAP=false
ARG RAILS_ENV=production
ARG NODE_ENV=production

ENV RAILS_ROOT /app
ENV RAILS_ENV=$RAILS_ENV
ENV NODE_ENV=$NODE_ENV
ENV BUNDLER_VERSION="2.2.17"
ENV SECRET_KEY_BASE=secret

RUN mkdir -p $RAILS_ROOT

WORKDIR $RAILS_ROOT

COPY config/database.yml.example config/database.yml

COPY . .
RUN bundle install
RUN yarn install --production=false
RUN if [ "$COMPILE_STATIC"  = "true" ] ; then bundle exec rails assets:precompile; fi
RUN if [ "$SITEMAP" = "true" ] ; then bundle exec rake sitemap:refresh:no_ping; fi

EXPOSE 3000

COPY docker/app/script/entrypoint.sh /entrypoint.sh

RUN \
 chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
