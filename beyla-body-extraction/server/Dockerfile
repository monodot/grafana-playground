FROM docker.io/library/node:22-alpine
WORKDIR /app
COPY package.json ./
RUN npm install
COPY index.js ./
EXPOSE 8080
CMD ["node", "index.js"]
