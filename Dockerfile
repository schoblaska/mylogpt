# Make sure it matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.1
FROM ruby:$RUBY_VERSION

RUN apt-get update -qq && \
    apt-get install -y build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

WORKDIR /app

ENV SINATRA_ENV="production" \
    BUNDLE_WITHOUT="development"

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 4567
CMD ["bundle", "exec","ruby", "app.rb", "-s", "puma", "-e", "production"]
