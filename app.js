require('dotenv').config();
require('./Mongo').connect();
const server = require('./server.js');

const port = process.env.PORT || 3000;
console.log('listen port', port);
const serverListen = server.listen(port);

module.exports = {
  app: server,
  serverlisten: serverListen,
  port,
};