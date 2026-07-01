# syntax=docker/dockerfile:1
FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev && \
    apk upgrade --no-cache && \
    rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx
COPY server.js ./
EXPOSE 5001
USER node
CMD ["node", "server.js"]
