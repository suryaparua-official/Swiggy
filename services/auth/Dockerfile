FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
RUN npm run build


FROM node:22-alpine

WORKDIR /app

RUN addgroup -g 1001 -S nodejs && adduser -S nodeapp -u 1001

COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

COPY --from=builder /app/dist ./dist

RUN chown -R nodeapp:nodejs /app
USER nodeapp

EXPOSE 5000

CMD ["node", "dist/index.js"]
