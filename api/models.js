const mongoose = require('mongoose');
const schema = require('./schemas');

const stores = mongoose.model('stores', schema.stores);
const stores_book = mongoose.model('stores_book', schema.stores_book);
const stores_opening = mongoose.model('stores_opening', schema.stores_opening);
const users = mongoose.model('users', schema.users);
const purchases = mongoose.model('purchases', schema.purchases);

module.exports = {
    stores,
    stores_book,
    stores_opening,
    users,
    purchases,
}