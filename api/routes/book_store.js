const mongoose = require('mongoose');
const { stores, stores_opening, stores_book, users, purchases } = require('../models');
const { dateToDouble }  = require('../../extension/dateTime');

const storeByTime = async (ctx) => {
    const { timeStamp } = ctx.request.body;
    
    let sp_time = timeStamp.split(' ');
    let time = dateToDouble(sp_time[0], sp_time[1]);
    let filter = { start: { $lte: time }, end: { $gte: time } };

    let week = await stores_opening.find(filter);
    let setType = new Set(week.map(x => x.store_id));    
    let book_stores = await stores.find({ _id: Array.from(setType)});

    ctx.body = book_stores.map(store => {
        let opening = week.filter(day => day.store_id == store._id);
        return { 
            storeName: store.storeName,
            openingHours: opening.map(day => ({
                sevenday: day.sevenday,
                timestamp: day.timestamp
            })),
        };
    });
}

const storeByDay = async (ctx) => {
    const { day } = ctx.request.body;
    let filter = { sevenday: day };
    let week = await stores_opening.find(filter);
    let setType = new Set(week.map(x => x.store_id));    
    let book_stores = await stores.find({ _id: Array.from(setType)});

    ctx.body = book_stores.map(store => {
        let opening = week.filter(day => day.store_id == store._id);
        return { 
            storeName: store.storeName,
            openingHours: opening.map(day => ({
                sevenday: day.sevenday,
                timestamp: day.timestamp
            })),
        };
    });
}

const storeByHour = async (ctx) => {
    const { days, hour, moreOrLess } = ctx.request.body;

    if(days == 1) {
        let filter = moreOrLess ? { hours: { $gte: hour } } : { hours: { $lte: hour } };
    
        let week = await stores_opening.find(filter);
        let setType = new Set(week.map(x => x.store_id));    
        let book_stores = await stores.find({ _id: Array.from(setType)});
        ctx.body = book_stores.map(store => {
            let opening = week.filter(day => day.store_id == store._id);
            return { 
                storeName: store.storeName,
                openingHours: opening.map(day => ({
                    sevenday: day.sevenday,
                    timestamp: day.timestamp,
                })),
            };
        });
    }
    else if (days == 7){
        let filter = [
            { $group: { _id: "$store_id", total: { $sum: "$hours" } } }
          ];
    
        let temp_week = await stores_opening.aggregate(filter);
        let setType = temp_week.map(x => {
            if (moreOrLess && x.total > hour) { return x._id; }
            if (!moreOrLess && x.total < hour) { return x._id; }
        });

        let week = await stores_opening.find({ store_id: setType });
        let book_stores = await stores.find({ _id: setType});

        ctx.body = book_stores.map(store => {
            let opening = week.filter(day => day.store_id == store._id);
            return { 
                storeName: store.storeName,
                openingHours: opening.map(x => ({
                    sevenday: x.sevenday,
                    timestamp: x.timestamp,
                })),
            };
        });
    }
}

const bookByPrice = async (ctx) => {
    const { price_low, price_high, sort_key, desc } = ctx.request.body;
    let filter = { $and: [ { price: { $gte: price_low } }, { price: { $lte: price_high } } ] };
    let sort = {};
    sort[sort_key] = desc ? -1 : 1;
    let books = await stores_book.find(filter).sort(sort);
    let setType = new Set(books.map(x => x.store_id));   
    let book_stores = await stores.find({ _id: Array.from(setType)});
    ctx.body = books.map(book => {
        let store = book_stores.find(store => store._id == book.store_id);
        return { 
            storeName: store.storeName,
            bookName: book.bookName,
            price: book.price
        };
    });
}

const storeByBookCount = async(ctx) => {
    const { sum, moreOrLess } = ctx.request.body;
    
    let book_stores = await stores.find({}).select('storeName');
    let map_store = await Promise.all(book_stores.map(async (store) => {
        let count = await stores_book.find({store_id:store._id}).count();
            return {
                storeName: store.storeName,
                sum: count
            };    
        }
    ));
    ctx.body = map_store.filter(store => (moreOrLess && store.sum > sum) || (!moreOrLess && store.sum < sum));
}

const storeByPrice = async(ctx) => {
    const { price_low, price_high,sum, moreOrLess } = ctx.request.body;
    
    let book_stores = await stores.find({}).select('storeName');
    let map_store = await Promise.all(book_stores.map(async (store) => {
        let filter =  {store_id:store._id, $and: [ { price: { $gte: price_low } }, { price: { $lte: price_high } } ] };
        let count = await stores_book.find(filter).count();
            return {
                storeName: store.storeName,
                sum: count
            };    
        }
    ));
    ctx.body = map_store.filter(store => (moreOrLess && store.sum > sum) || (!moreOrLess && store.sum < sum));
}

const searchByName = async(ctx) => {
    const {table, name } = ctx.request.body;
    if (table == 'store') {
        let precise = await stores.find({ storeName: name });
        let fuzzy = await stores.find({ storeName: new RegExp(name) });
        let concat_list =  precise.concat(fuzzy);
        let concat_map = concat_list.map(x => x.storeName.toString());
        let concat_repeact = concat_list.filter((item, pos) => (concat_map.indexOf(item.storeName.toString())) == pos);
        ctx.body = concat_repeact.map(store => store.storeName);
    }
    else if (table == 'book') {
        let precise = await stores_book.find({ bookName: name });
        let fuzzy = await stores_book.find({ bookName: new RegExp(name) });
        let concat_list =  precise.concat(fuzzy);
        let concat_map = concat_list.map(x => x.bookName.toString());
        let concat_repeact = concat_list.filter((item, pos) => (concat_map.indexOf(item.bookName.toString())) == pos)
        ctx.body = concat_repeact.map(book => book.bookName);
    }
}

const userByVIP = async(ctx) => {
    const { time_start, time_end, count } = ctx.request.body;
    let filter = [
        { $match: { transactionDate: { $gt: new Date(time_start), $lt: new Date(time_end) } } },
        { $group: { _id : "$user_id", total: { $sum: "$transactionAmount" } } },
        { $sort : { total : -1 } }
    ];
    const aggregate = await purchases.aggregate(filter).limit(count);
    ctx.body = await Promise.all(aggregate.map(async(user) => {
        const data = await users.findById(user._id);
        return {
            name: data.name,
            total: user.total
        }
    }));
}


const priceByDate = async(ctx) => {
    const { time_start, time_end } = ctx.request.body;
    let filter = { transactionDate: { $gt: new Date(time_start), $lt: new Date(time_end) } };
    const records = await purchases.find(filter);
    let totals = records.reduce((x, y) => {
        return { transactionAmount: parseFloat((x.transactionAmount + y.transactionAmount).toFixed(2))};
    });
    ctx.body = {
        count: records.length,
        total: totals.transactionAmount
    }
}

const editData = async (ctx) => {
    const { user_id, store_id, book_id, userNewName, storeNewName, bookNewName, bookNewPrice } = ctx.request.body;
    let model;
    let filter;
    let update;
    if(user_id) {
        filter = { _id: user_id };
        update = { $set: { name: userNewName } };
        model = users;
    }
    else if (store_id) {
        filter = { _id: store_id };
        update = { $set: { storeName: storeNewName } };
        model = stores;
    }
    else if (book_id) {
        filter = { _id: book_id };
        update = { $set: { bookName: bookNewName, price: bookNewPrice } };
        model = stores_book;
    }
    ctx.body = await model.updateOne(filter, update);
}

const storeByPopular = async(ctx) => {
    const { key } = ctx.request.body;
    let filter;
    if(key == "account") {
        filter = [
            { $group: { _id : "$store_id", total: { $sum: "$transactionAmount" } } },
            { $sort : { total : -1 } }
        ];
    }
    else if (key == "times") {
        filter = [
            { $group: { _id : "$store_id", count: { $sum: 1 } } },
            { $sort : { count : -1 } }
        ];
    }
    const aggregate = await purchases.aggregate(filter).limit(1);
    const { storeName } =  await stores.findById(aggregate[0]._id);
    ctx.body = storeName;
}

const userByDateAmountRange = async(ctx) => {
    const { amount_start, amount_end,time_start, time_end } = ctx.request.body;
    let filter = [
        { $match: { transactionDate: { $gt: new Date(time_start), $lt: new Date(time_end) } } },
        { $group: { _id : "$user_id", total: { $sum: "$transactionAmount" } } },
        { $sort : { total : -1 } }
    ];
    const aggregate = await purchases.aggregate(filter);
    ctx.body = aggregate.filter(user => (user.total > amount_start) && (user.total < amount_end)).length;
}
const transaction = async(ctx) => {
    const { user_id, store_id, amount } = ctx.request.body;

    const session = await mongoose.startSession();
    session.startTransaction();
    let response;

    try {
        const sender = await users.findOne({ _id: user_id }).session(session);
        sender.cashBalance -= amount;
        if (sender.cashBalance < 0) {
        throw new Error('Insufficient Balance');
        }
        await sender.save();

        const receiver = await stores.findOne({ _id: store_id }).session(session);
        receiver.cashBalance += amount;
        await receiver.save();

        await session.commitTransaction();
        response = {
            user: {
                _id: user_id,
                cashBalance: sender.cashBalance
            },
            store: {
                _id: user_id,
                cashBalance: receiver.cashBalance
            }
        }
    }
    catch (error) {
        await session.abortTransaction();
        response = error.message;
    } 
    finally {
        session.endSession();
        ctx.body = response;
    }
}

module.exports = {
    storeByTime,
    storeByDay,
    storeByHour,
    bookByPrice,
    storeByBookCount,
    storeByPrice,
    searchByName,
    userByVIP,
    priceByDate,
    editData,
    storeByPopular,
    userByDateAmountRange,
    transaction
}
