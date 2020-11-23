FROM node:14.15.1-alpine
ENV NODE_ENV development
WORKDIR /usr/src/app
HEALTHCHECK --interval=1m --timeout=10s --start-period=10s --retries=3 CMD curl --insecure -f http://localhost:3001/api/ || exit 1
EXPOSE 3001

RUN npm install -g typescript
COPY ["package.json", "package-lock.json", "tsconfig.json", "./"]
RUN npm install --production --silent
COPY ["./src", "./src/"]
RUN tsc --build tsconfig.json
RUN mv ./src/config.json ./dist && rm -rf src

CMD npm start