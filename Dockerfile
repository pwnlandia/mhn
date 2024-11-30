# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache python3 make g++

COPY package*.json ./
COPY api/package*.json ./api/

# Install dependencies
RUN npm ci
RUN cd api && npm ci

# Copy source code and Prisma schema
COPY . .

# Generate Prisma client and build
RUN cd api && npx prisma generate
RUN npm run api:build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Install production dependencies
RUN apk add --no-cache python3 make g++

COPY --from=builder /app/api/dist ./dist
COPY --from=builder /app/api/package*.json ./
COPY --from=builder /app/api/prisma ./prisma
COPY --from=builder /app/api/node_modules/.prisma ./node_modules/.prisma

# Install production dependencies
RUN npm ci --only=production

# Environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose API port
EXPOSE 3000

# Start the server
CMD ["node", "dist/app.js"]