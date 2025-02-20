FROM docker.io/library/node:22

COPY . /app

WORKDIR /app

RUN npm install
EXPOSE 3000

CMD ["npm", "run", "start:log"]
