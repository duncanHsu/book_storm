 const errorStatus = async (ctx, next) => {
    try {
      await next();
    } catch (err) {
      ctx.status = err.status || 404;
      ctx.body = err.message;
    }
  }
  
  const logger = async (ctx, next) => {
    const start = Date.now();
    await next().then(() => {
      const ms = Date.now() - start;
      console.log(`${ctx.method} ${ctx.url} - ${ms}ms`);
    });
  }
  
  module.exports = {
    errorStatus,
    logger,
  };
  