'use strict';

const fs = require('fs');
const path = require('path');
const { start } = require('repl');

module.exports = {
  up: async (queryInterface, Sequelize) => {
    let rawdata = fs.readFileSync(path.resolve(__dirname, '..', 'data', 'user_data.json'));
    const users = JSON.parse(rawdata);
    const ums = [];
    const phms = [];
    for (const user of users) {
      const d = new Date();
      ums.push({id: user.id, name: user.name, cashBalance: user.cashBalance, createdAt: d, updatedAt: d});
      for (const ph of user.purchaseHistory) {
        phms.push({userId: user.id, storeName: ph.storeName, bookName: ph.bookName, transactionAmount: ph.transactionAmount, transactionDate: new Date(ph.transactionDate), createdAt: d, updatedAt: d});
      }
    }
    // console.log(phms);
    await queryInterface.bulkInsert('Users', ums);
    await queryInterface.bulkInsert('PurchaseHistory', phms);
    console.log('Importing "user_data.json" is complete!');

    rawdata = fs.readFileSync(path.resolve(__dirname, '..', 'data', 'book_store_data.json'));
    const bookStores = JSON.parse(rawdata);
    const sms = [];
    const bms = [];
    const ohms = [];
    let storeId = 0;
    for (const bs of bookStores) {
      storeId += 1;
      const d = new Date();
      sms.push({name: bs.storeName, cashBalance: bs.cashBalance, createdAt: d, updatedAt: d});
      for (const book of bs.books) {
        bms.push({storeId: storeId, name: book.bookName, price: book.price, createdAt: d, updatedAt: d});
      }

      const weekHours = bs.openingHours.split(' / ');
      const weekReg = /(Mon|Tues|Wed|Thurs|Fri|Sat|Sun)+/g;
      const timeReg = /(\d)+:?(\d)*\s(am|pm)/g;
      for (const wh of weekHours) {
        const weeks = wh.match(weekReg);
        const times = wh.match(timeReg);
        const startTime = times[0];
        const endTime = times[1];
        if (weeks.length >= 2 && wh.substr(weeks[0].length + 1, 1) == '-') {
          const fromWeek = weeks[0];
          const toWeek = weeks[1];
          const fromWeekInt = weekToInt(fromWeek);
          const toWeekInt = weekToInt(toWeek);
          if (toWeekInt - fromWeekInt > 1) {
            for (let index = fromWeekInt + 1; index < toWeekInt; index++) {
              const newWeekInt = weekFromInt(index);
              weeks.push(newWeekInt);
            }
          }
        }
        for (const week of weeks) {
          const weekInt = weekToInt(week);
          const startMinutes = toMin(startTime);
          const endMinutes = toMin(endTime);
          let openMinutes= endMinutes - startMinutes;
          if (openMinutes < 0) {
            openMinutes = (24 * 60 - startMinutes) + endMinutes;
          }
          ohms.push({storeId: storeId, week: weekInt, startMinutes: startMinutes, endMinutes: endMinutes, openMinutes: openMinutes, createdAt: d, updatedAt: d});
        }
      }
    }
    // console.log(ohms);
    // console.log(bms);
    await queryInterface.bulkInsert('Stores', sms);
    await queryInterface.bulkInsert('Books', bms);
    await queryInterface.bulkInsert('OpeningHours', ohms);
    console.log('Importing "book_store_data.json" is complete!');
  },

  down: async (queryInterface, Sequelize) => {
    console.log('down');
  },
};

function toMin(value) {
  const time = value.split(' ');
  const isPm = (time[1] == 'pm');
  const hourMin = time[0];
  const hms = hourMin.split(':');
  let result = (hms.length > 1 ? +(hms[1]) : 0);
  result += +(hms[0]) * 60;
  if (isPm) {
    result += 12 * 60;
  }
  return result;
}

function weekToInt(week) {
  if (week == 'Mon') {
    return 1;
  } else if (week == 'Tues') {
    return 2;
  } else if (week == 'Wed') {
    return 3;
  } else if (week == 'Thurs') {
    return 4;
  } else if (week == 'Fri') {
    return 5;
  } else if (week == 'Sat') {
    return 6;
  }
  return 7;
}

function weekFromInt(value) {
  if (value == 1) {
    return 'Mon';
  } else if (value == 2) {
    return 'Tues';
  } else if (value == 3) {
    return 'Wed';
  } else if (value == 4) {
    return 'Thurs';
  } else if (value == 5) {
    return 'Fri';
  } else if (value == 6) {
    return 'Sat';
  }
  return 'Sun';
}


