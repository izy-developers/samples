FROM ruby:3.0.1-buster

LABEL maintainer="IZY <pingpong@izy-developers.com>"

ENV RAILS_ROOT /app
ENV BUNDLER_VERSION="2.2.17"

RUN mkdir -p $RAILS_ROOT

WORKDIR $RAILS_ROOT

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

COPY package.json package.json
COPY yarn.lock yarn.lock

RUN apt-get update && apt-get -y install build-essential apt-transport-https lsb-release ca-certificates curl cmake

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y nodejs yarn
RUN rm -rf /var/lib/apt/lists/*

RUN gem install bundler --version "${BUNDLER_VERSION}"
RUN bundle install
RUN yarn install --production=false
