FROM node:20-slim AS build

# Set working directory for build stage
WORKDIR /app

# Copy package manifests and install dependencies
COPY package.json package-lock.json ./
RUN npm install --legacy-peer-deps

# Copy the rest of the client source and build the production bundle
COPY . .
RUN npm run build

# Final stage: serve the compiled React app with a lightweight HTTP server
FROM node:20-slim

WORKDIR /app

# Install the serve package globally to serve static files
RUN npm install -g serve

# Copy build artifacts from the previous stage
COPY --from=build /app/build ./build

# Expose the port configured in docker-compose
EXPOSE 3000

# Start the static file server
CMD ["serve", "-s", "build", "-l", "3000"]