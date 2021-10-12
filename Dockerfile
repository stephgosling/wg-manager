# Frontend builder, deps only
FROM node:16 AS frontendbuilder
WORKDIR /app
COPY wg-manager-frontend/package*.json /app/
RUN npm ci

FROM node:16 AS frontend
WORKDIR /app
COPY --from=frontendbuilder /app/node_modules /app/node_modules
COPY wg-manager-frontend /app/
RUN npm run build

# Backend builder, deps only
FROM ubuntu:20.04
LABEL maintainer="per@sysx.no"
ENV IS_DOCKER True
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends\
  wireguard-tools \
  iptables \
  iproute2 \
  python3 \
  python3-pip \
  python3-dev \
  && rm -rf /var/lib/apt/lists/*

COPY wg-manager-backend/requirements.txt /app/
RUN pip3 install -r requirements.txt

# Copy startup scripts
COPY wg-manager-backend /app/
COPY docker/ ./startup
RUN chmod 700 ./startup/start.py

# Copy build files from previous step
COPY --from=frontend /app/dist /app/build

ENTRYPOINT python3 startup/start.py
