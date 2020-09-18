
const mongoose = require('mongoose');
const models = require('../api/models');
const { sevendayToInt, sevendayToString, dateConvert, dateToDouble } = require('../extension/dateTime');
const book_store_data = require('../seeds/book_store_data.json');
const user_data = require('../seeds/user_data.json');

const mirgrateStoreData = async () => {
    for(let i = 0; i < book_store_data.length; i++) {
        const model_store = new models.stores();
        model_store.storeName = book_store_data[i].storeName;
        model_store.cashBalance = book_store_data[i].cashBalance;
        let { _id: store_id  } = await model_store.save();

        let books_data = book_store_data[i].books;
        for(let j = 0; j < books_data.length;j++) {
            const model_store_book = new models.stores_book();
            model_store_book.store_id = store_id;
            model_store_book.bookName = books_data[j].bookName;
            model_store_book.price =  books_data[j].price;
            await model_store_book.save();
        }

        let openHour = book_store_data[i].openingHours.split(' / ');
        for(let j = 0; j < openHour.length;j++) {
            let cross = false;
            let subNumber = openHour[j].search(/[0-9]/);
            let week = openHour[j].substring(0, subNumber - 1);
            let time = openHour[j].substring(subNumber, openHour[j].length);
            let sp_week = week.split(/, | - /);
            let sp_time = time.split(/ - |[ ]/);
            
            let time_start = dateConvert(sp_time[0], sp_time[1]);
            let time_end = dateConvert(sp_time[2], sp_time[3]);
            let time_diff = (time_end - time_start) / ( 60 * 60 * 1000);
            if (time_diff < 0) { 
                cross = true;
                time_diff = 24 + time_diff;
            }

            let week_start = 0;
            let week_end = 0;
            if (sp_week.length > 1 ) {
                week_start = sevendayToInt[sp_week[0]];
                week_end = sevendayToInt[sp_week[1]];
            }
            else {
                week_start = sevendayToInt[sp_week[0]];
                week_end = sevendayToInt[sp_week[0]];
            }
            
            for (let i = week_start; i<= week_end; i++) {
                const model_stores_opening = new models.stores_opening();
                model_stores_opening.store_id = store_id;
                model_stores_opening.sevenday = sevendayToString[i];
                model_stores_opening.start = dateToDouble(sp_time[0], sp_time[1], false);
                model_stores_opening.end = dateToDouble(sp_time[2], sp_time[3], cross);
                model_stores_opening.hours = time_diff;
                model_stores_opening.timestamp = `${sp_time[0]} ${sp_time[1]} - ${sp_time[2]} ${sp_time[3]}`;
                await model_stores_opening.save();
            }
        }
    }    
};

const mirgrateUserData = async () => {
    const response_store = await models.stores.find({});
    let stores = {};
    response_store.forEach(e => {
        stores[e.storeName] = { _id: e._id };
    });
    for(let i = 0; i < user_data.length; i++) {
        const model_user = new models.users();
        model_user.id = user_data[i].id;
        model_user.cashBalance = user_data[i].cashBalance;
        model_user.name = user_data[i].name;
        let { _id: user_id  } = await model_user.save();
        let records = user_data[i].purchaseHistory;
        for(let j = 0; j < records.length; j++) {
            let record = records[j];
            let store_id = stores[record.storeName]._id
            let book = await models.stores_book.findOne({ store_id, bookName: record.bookName })
            const model_purchases = new models.purchases();
            model_purchases.user_id = user_id;
            model_purchases.store_id = store_id;
            model_purchases.book_id = book._id;
            model_purchases.transactionAmount = record.transactionAmount;
            model_purchases.transactionDate = record.transactionDate;
            await model_purchases.save();
        }
    }
};

module.exports = {
    mirgrateStoreData,
    mirgrateUserData
}