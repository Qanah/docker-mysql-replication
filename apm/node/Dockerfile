FROM node:20

WORKDIR /app
COPY . .

RUN npm install

ENV ELASTIC_APM_SERVER_URL=http://apm-server:8200
ENV ELASTIC_APM_SERVICE_NAME=node-app

CMD ["node", "index.js"]