FROM node:8-alpine
WORKDIR /app
ADD . /app
RUN npm install --production
EXPOSE 3000
CMD ["npm", "start"]
