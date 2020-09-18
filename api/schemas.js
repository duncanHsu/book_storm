const { Schema, model } = require('mongoose');

const stores = new Schema({
    storeName: String,
    cashBalance: Number
});

const stores_book = new Schema({
    store_id: String,
    bookName: String,
    price: Number
});

const stores_opening = new Schema({
    store_id: String,
    sevenday: String,
    start: Number,
    end: Number,
    hours: Number,
    timestamp: String
});

const users = new Schema({
    id: Number,
    name: String,
    cashBalance: Number,
});

const purchases = new Schema({
    user_id: String,
    store_id: String,
    book_id: String,
    transactionAmount: Number,
    transactionDate: Date
});

module.exports = {
    stores,
    stores_book,
    stores_opening,
    users,
    purchases
};
