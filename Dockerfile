# everything below sets up and runs lighthouse
FROM node:16-bullseye-slim

# Install Chromium and required dependencies
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-sandbox \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    fonts-thai-tlwg \
    fonts-kacst \
    fonts-freefont-ttf \
    dumb-init \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Configure environment variables for Puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV CHROME_PATH "/usr/bin/chromium"
ENV PUPPETEER_EXECUTABLE_PATH "/usr/bin/chromium"
# Additional flags needed for running Chromium in Docker
ENV PUPPETEER_ARGS="--no-sandbox,--disable-gpu,--disable-dev-shm-usage"

USER node

ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=$PATH:/home/node/.npm-global/bin

WORKDIR /home/node/app

# install all dev and production dependencies
COPY --chown=node:node package.json .
COPY --chown=node:node yarn.lock .
RUN yarn install

# build and copy the app over
COPY --chown=node:node src ./src
COPY --chown=node:node tsconfig.json .
RUN yarn build

ENV NODE_ENV production

# prune out dev dependencies now that build has completed
RUN yarn install --production

CMD ["dumb-init", "node", "cjs/run.js"]
