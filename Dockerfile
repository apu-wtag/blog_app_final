ARG RUBY_VERSION=3.4.4
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base
# Rails app lives here
WORKDIR /rails
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential curl git libpq-dev libvips postgresql-client libyaml-dev pkg-config  watchman && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
# Set development environment
ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT=""
# Install application gems
RUN gem install bundler -v 2.7.1
COPY Gemfile Gemfile.lock ./
RUN bundle install
# Copy application code
COPY . .
COPY bin/docker-entrypoint /usr/bin/docker-entrypoint
RUN chmod +x /usr/bin/docker-entrypoint
ENTRYPOINT ["/usr/bin/docker-entrypoint"]
EXPOSE 3000
