FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm install -g concurrently

# Expose 3 service ports
EXPOSE 5050 6000 5053

CMD ["concurrently", "node workflow-api.js", "node mock-check-service.js", "node proxy.js"]
