FROM node:20-slim

WORKDIR /app

COPY . .

RUN npm install --legacy-peer-deps

ENTRYPOINT ["node", "github-recon.js"]