const mongoose = require('mongoose');

const DB_URI = `${process.env.DB_USERNAME}:${process.env.DB_PASSWARD}@mongodb://${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`;

const connect = async() => {
  try {
      await mongoose.connect(DB_URI, {
      useUnifiedTopology: true,
      useNewUrlParser: true,
      useFindAndModify: false
    });
    console.log(`mongodb connect success:${DB_URI}`);
  } catch (err) {
    console.log(`[Error] mongodb connect fail:${DB_URI} ${err}`);
  }
}

const disconnect = async() => {
  mongoose.disconnect();
}

module.exports = {
  connect,
  disconnect
};
