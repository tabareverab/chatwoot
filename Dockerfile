# syntax=docker/dockerfile:1.6

## ---------- Build stage ----------
FROM ruby:3.2-bookworm AS build
ENV RAILS_ENV=production NODE_ENV=production
WORKDIR /app

# deps de sistema + Node 20 + Yarn (corepack)
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential git curl python3 pkg-config libvips postgresql-client ca-certificates \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && corepack enable && corepack prepare yarn@stable --activate

# instalar gems y paquetes JS primero (mejor cache)
COPY Gemfile Gemfile.lock package.json yarn.lock ./
RUN gem install bundler -N \
 && bundle config set deployment 'true' \
 && bundle config set without 'development test' \
 && bundle install
RUN yarn install --frozen-lockfile || yarn install

# copiar el resto y precompilar assets (Vite + Rails)
COPY . .
ENV RAILS_SERVE_STATIC_FILES=true
RUN bundle exec rake assets:precompile

## ---------- Runtime stage ----------
FROM ruby:3.2-bookworm AS app
ENV RAILS_ENV=production RAILS_SERVE_STATIC_FILES=true RAILS_LOG_TO_STDOUT=true
WORKDIR /app

# runtime mínimo (libvips para procesamiento de imágenes, psql client para tareas DB)
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libvips postgresql-client ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /app /app
EXPOSE 3000

# Importante: SECRET_KEY_BASE, DATABASE_URL y REDIS_URL deben venir por env en el server
CMD ["bash","-lc","bundle exec rake db:chatwoot_prepare && bundle exec puma -C config/puma.rb"]
