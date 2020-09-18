const mongoose = require('mongoose');
const command = require('../../command/mirgrate_book_storm');
const models = require('../../api/models');
const routes = require('../../api/routes/book_store');
const { checkDuplicationNormal } = require('../../extension/calculation')

beforeAll(async () => {
  let uri = global.__MONGO_URI__;
  // atomic transaction
  uri = 'mongodb://DESKTOP-G48DHT9:27017/book_storm?retryWrites=false';
  await mongoose.connect(uri, {
    useUnifiedTopology: true,
    useNewUrlParser: true,
    useFindAndModify: false,
  });
  
  await command.mirgrateStoreData();
  await command.mirgrateUserData();
});

afterAll(async () => {
  await mongoose.disconnect();
});

describe('Api Test', () => {
  it('storeByTime', async () => {
      const ctx = { 
        request: {
          body: {
            timeStamp: "07:00 pm"
          }
        }
      };
      await routes.storeByTime(ctx);

      const store = ctx.body[0];
      expect(store.storeName).toBe('Look Inna Book');
      const openingHours = store.openingHours[0];
      expect(openingHours.sevenday).toBe('Mon');
      expect(openingHours.timestamp).toBe('2:30 pm - 8 pm');
  });

  it('storeByDay', async () => {
      const ctx = { 
        request: {
          body: {
           day: "Wed"
           }
        }
      };
      await routes.storeByDay(ctx);
      const store = ctx.body[0];
      expect(store.storeName).toBe('Look Inna Book');
      const openingHours = store.openingHours[0];
      expect(openingHours.sevenday).toBe('Wed');
      expect(openingHours.timestamp).toBe('2:30 pm - 8 pm');
  });

  it('storeByHour: day', async () => {
      const ctx = { 
        request: {
          body: {
            days: 1,
            hour: 5,
            moreOrLess: false
          }
        }
      };
      await routes.storeByHour(ctx);
      const store = ctx.body[0];
      expect(store.storeName).toBe('Look Inna Book');
      const openingHours = store.openingHours[0];
      expect(openingHours.sevenday).toBe('Tues');
      expect(openingHours.timestamp).toBe('11 am - 2 pm');
  });

  it('storeByHour: week', async () => {
      const ctx = { 
        request: {
          body: {
            days: 7,
            hour: 100,
            moreOrLess: true
          }
        }
      };
      await routes.storeByHour(ctx);
      const store = ctx.body[0];
      expect(store.storeName).toBe('The Book Basement');
  });

  it('bookByPrice sort: price', async () => {
      const ctx = { 
        request: {
          body: {
            price_low: 13.5,
            price_high: 14,
            sort_key: 'price',
            desc: true
          }
        }
      };
      await routes.bookByPrice(ctx);
      const book = ctx.body[0];
      expect(book.storeName).toBe('Look Inna Book');
      expect(book.bookName).toBe('Ruby Holler');
      expect(book.price).toBe(14);
  });

  it('bookByPrice sort: bookName', async () => {
      const ctx = { 
        request: {
          body: {
            price_low: 13.5,
            price_high: 14,
            sort_key: 'bookName',
            desc: true
          }
        }
      };
      await routes.bookByPrice(ctx);
      const book = ctx.body[0];
      expect(book.storeName).toBe('Look Inna Book');
      expect(book.bookName).toBe("Where's Ruby? (max And Ruby)");
      expect(book.price).toBe(13.5);
  });

  it('storeByBookCount', async () => {
      const ctx = { 
        request: {
          body: {
          sum: 10,
          moreOrLess: true
          }
        }
      };
      await routes.storeByBookCount(ctx);
      const store = ctx.body[0];
      expect(store.storeName).toBe('Look Inna Book');
      expect(store.sum).toBe(14);
  });

  it('storeByPrice', async () => {
    const ctx = { 
      request: {
        body: {
          price_low: 1,
          price_high: 8,
          sum: 1,
          moreOrLess: true
        }
      }
    };
    await routes.storeByPrice(ctx);
    const store = ctx.body[0];
    expect(store.storeName).toBe('A Whole New World Bookstore');
  });

  it('searchByName: store', async () => {
    const ctx = { 
      request: {
        body: {
          table: 'store',
          name: 'Look Inna Book'
        }
      }
    };
    await routes.searchByName(ctx);
    const storeName = ctx.body[0];
    expect(storeName).toBe('Look Inna Book');
  });

  it('searchByName: book', async () => {
    const ctx = { 
      request: {
        body: {
          table: 'book',
          name: 'Elixir'
        }
      }
    };
    await routes.searchByName(ctx);
    expect(checkDuplicationNormal(ctx.body)).toBeFalsy();
  });

  it('userByVIP', async () => {
    const ctx = { 
      request: {
        body: {
          time_start: '01/01/2000 00:00 AM',
          time_end: '01/10/2021 00:00 AM',
          count: 3
        }
      }
    };
    await routes.userByVIP(ctx);
    let user = ctx.body[0];
    expect(user.name).toBe('Coy Mincks');
    expect(user.total).toBe(193.56);
  });

  it('priceByDate', async () => {
    const ctx = { 
      request: {
        body: {
          time_start: '05/01/2020 00:00 AM',
          time_end: '12/31/2020 00:00 AM',
        }
      }
    };
    await routes.priceByDate(ctx);
    expect(ctx.body.count).toBe(4);
    expect(ctx.body.total).toBe(44.02);
  });

  it('storeByPopular: account', async () => {
    const ctx = { 
      request: {
        body: {
          key: 'account'
        }
      }
    };
    await routes.storeByPopular(ctx);
    expect(ctx.body).toBe('Turn the Page');
  });

  it("editData: user update", async () => {
    const user = await models.users.findOne({ name: 'Edith Johnson' });
    const ctx = { 
      request: {
        body: {
          user_id: user._id,
          userNewName: 'Edith Johnson Test'
        }
      }
    };
    await routes.editData(ctx);
    const expect_user = await models.users.findOne({ _id: user._id });
    expect(expect_user.name).toBe('Edith Johnson Test');
  });

  it("editData: store update", async () => {
    const store = await models.stores.findOne({ storeName: 'Look Inna Book' });
    const ctx = { 
      request: {
        body: {
          store_id: store._id,
          storeNewName: 'Look Inna Book Test'
        }
      }
    };
    await routes.editData(ctx);
    const expect_store = await models.stores.findOne({ _id: store._id });
    expect(expect_store.storeName).toBe('Look Inna Book Test');
  });

  it("editData: book update", async () => {
    const book = await models.stores_book.findOne({ bookName: 'Ruby: The Autobiography' });
    const ctx = { 
      request: {
        body: {
          book_id: book._id,
          bookNewName: 'Ruby: The Autobiography Test',
          bookNewPrice: 13
        }
      }
    };
    await routes.editData(ctx);
    const expect_book = await models.stores_book.findOne({ _id: book._id });
    expect(expect_book.bookName).toBe('Ruby: The Autobiography Test');
    expect(expect_book.price).toBe(13);
  });

  it('storeByPopular: times', async () => {
    const ctx = { 
      request: {
        body: {
          key: 'times'
        }
      }
    };
    await routes.storeByPopular(ctx);
    expect(ctx.body).toBe('Turn the Page');
  });

  it('storeByPopular: times', async () => {
    const ctx = { 
      request: {
        body: {
          key: 'times'
        }
      }
    };
    await routes.storeByPopular(ctx);
    expect(ctx.body).toBe('Turn the Page');
  });

  it('userByDateAmountRange: times', async () => {
    const ctx = { 
      request: {
        body: {
          amount_start: 35,
          amount_end: 100,
          time_start: '01/01/2020 00:00 AM',
          time_end: '12/31/2020 00:00 AM'
        }
      }
    };
    await routes.userByDateAmountRange(ctx);
    expect(ctx.body).toBe(3);
  });

  it('transaction', async () => {
    let store = await models.stores.findOne({ storeName: 'The Book Basement' });
    let user = await models.users.findOne({ name: 'Edward Gonzalez' });
    const ctx = { 
      request: {
        body: {
          user_id: user._id,
          store_id: store._id,
          amount: 100
        }
      }
    };
    await routes.transaction(ctx);
    expect(ctx.body.user.cashBalance).toBe(137.61);
    expect(ctx.body.store.cashBalance).toBe(4982.81);
  });

  it('[error] transaction: Insufficient Balance', async () => {
    let store = await models.stores.findOne({ storeName: 'The Book Basement' });
    let user = await models.users.findOne({ name: 'Heather Edwards' });
    const ctx = { 
      request: {
        body: {
          user_id: user._id,
          store_id: store._id,
          amount: 1000
        }
      }
    };
    await routes.transaction(ctx);
    expect(ctx.body).toBe('Insufficient Balance');
  });
});
