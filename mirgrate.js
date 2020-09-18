require('dotenv').config();
const command = require('./command/mirgrate_book_storm');
const { connect, disconnect } = require('./Mongo/index');

const run = async() => {
    await connect();
    await command.mirgrateStoreData();
    await command.mirgrateUserData();
    await disconnect();
}
run();