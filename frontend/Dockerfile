FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY index.html ./
COPY tsconfig.json vite.config.ts ./
COPY src ./src
COPY tailwind.config.js postcss.config.js ./

EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
