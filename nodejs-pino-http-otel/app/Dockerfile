FROM docker.io/library/node:22

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "--require", "./instrumentation.js", "server.js"]
