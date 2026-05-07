FROM node:24-alpine as builder

## Install build toolchain, install node deps and compile native add-ons
RUN apk add --no-cache python3 make g++ linux-headers

WORKDIR app
RUN chown node:node ./
USER node

ARG NODE_ENV=production
ENV NODE_ENV $NODE_ENV

COPY package-lock.json .
COPY package.json .
RUN npm ci && npm cache clean --force
# rebuild from sources to avoid issues with prebuilt binaries (https://github.com/serialport/node-serialport/issues/2438
# RUN npm ci --omit=dev && npm rebuild --build-from-source

FROM node:24-alpine as app

## Copy built node modules and binaries without including the toolchain
COPY --from=builder app/node_modules ./node_modules

# Copy root filesystem
COPY warema-bridge/srv .

CMD ["node", "index.js"]
