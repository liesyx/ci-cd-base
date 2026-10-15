# ---- base ----
FROM node:20-alpine AS base
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY server.js ./

# ---- test (CI runs: docker build --target test) ----
FROM base AS test
COPY test.js ./
RUN npm test

# ---- runtime ----
FROM base AS runtime
ENV NODE_ENV=production
USER node
EXPOSE 3000
CMD ["node", "server.js"]
