# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json .
RUN npm install --only=production

# Production stage
FROM node:18-alpine
WORKDIR /app

# Copier seulement les fichiers nécessaires
COPY --from=builder /app/node_modules ./node_modules
COPY package.json .
COPY server.js .

# Créer un utilisateur non-root pour la sécurité
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3000

CMD ["node", "server.js"]