const Router = require('koa-router');
const book_store = require('./routes/book_store');

const router = new Router();

router.get('/', () => { ctx.body = 'hello world'; });
router.get('/storeByTime', book_store.storeByTime);
router.get('/storeByDay', book_store.storeByDay);
router.get('/storeByHour', book_store.storeByHour);
router.get('/bookByPrice', book_store.bookByPrice);
router.get('/storeByBookCount', book_store.storeByBookCount);
router.get('/storeByPrice', book_store.storeByPrice);
router.get('/searchByName', book_store.searchByName);
router.get('/userByVIP', book_store.userByVIP);
router.get('/priceByDate', book_store.priceByDate);
router.post('/editData', book_store.editData);
router.get('/storeByPopular', book_store.storeByPopular);
router.get('/userByDateAmountRange', book_store.userByDateAmountRange);
router.post('/transaction', book_store.transaction);

module.exports = router;
