const Koa = require('koa');
const bodyParser = require('koa-bodyparser');
const compress = require('koa-compress');
const zilb = require('zlib');
const Router = require('koa-router');
const middleware = require('./api/middleware');
const apiRouter = require('./api');

const koa = new Koa();

const routerVer = new Router();
routerVer.use(apiRouter.routes(), apiRouter.allowedMethods());

koa.use(middleware.errorStatus);
koa.use(middleware.logger);
koa.use(bodyParser());
koa.use(routerVer.routes(), routerVer.allowedMethods());
koa.use(compress({ flush: zilb.Z_SYNC_FLUSH }));

module.exports = koa;
