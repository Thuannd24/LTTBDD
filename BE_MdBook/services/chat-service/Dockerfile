FROM node:20-slim AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev

FROM node:20-slim
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=5006

RUN useradd -m appuser
COPY --from=deps /app/node_modules ./node_modules
COPY . .

EXPOSE 5006
USER appuser
CMD ["node", "server.js"]
