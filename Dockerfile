FROM ruby:3.2-bookworm AS build
ENV RAILS_ENV=production NODE_ENV=production
WORKDIR /app

# system deps + Node 20 + Yarn classic
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential git curl python3 pkg-config ca-certificates \
    libvips-dev libpq-dev postgresql-client \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm i -g yarn@1.22.22

# install gems & js deps first (better caching)
COPY Gemfile Gemfile.lock package.json yarn.lock ./
RUN gem install bundler -N \
 && bundle config set deployment 'true' \
 && bundle config set without 'development test' \
 && bundle install
RUN yarn install --frozen-lockfile --network-timeout 300000 || yarn install

# app source + assets build
COPY . .
ENV RAILS_SERVE_STATIC_FILES=true SECRET_KEY_BASE=dummy
RUN bundle exec rake assets:precompile

## ---------- Runtime stage ----------
FROM ruby:3.2-bookworm AS app
ENV RAILS_ENV=production RAILS_SERVE_STATIC_FILES=true RAILS_LOG_TO_STDOUT=true
WORKDIR /app

# minimal runtime deps
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libvips libpq5 postgresql-client ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /app /app
EXPOSE 3000
# DATABASE_URL, REDIS_URL y SECRET_KEY_BASE reales van por env en el server
CMD ["bash","-lc","bundle exec rake db:chatwoot_prepare && bundle exec puma -C config/puma.rb"]
