import { Config } from "config";
import { Sequelize } from 'sequelize';
import { BookRepository } from "./repository/book";
import { OpeningHourRepository } from "./repository/openingHour";
import { PurchaseHistoryRepository } from "./repository/purchaseHistory";
import { StoreRepository } from "./repository/store";
import { UserRepository } from "./repository/user";

export class DatabaseManager
{
    private config: Config;
    public sequelize: Sequelize;
    
    public bookRepo: BookRepository;
    public openingHourRepo: OpeningHourRepository;
    public purchaseHistoryRepo: PurchaseHistoryRepository;
    public storeRepo: StoreRepository;
    public userRepo: UserRepository;

    constructor(config: Config) {
        this.config = config;
    }

    public async load() {
        const database = this.config.database;
        this.sequelize = new Sequelize(database.name, database.username, database.password, {
            host: database.host,
            port: database.port,
            dialect: database.dialect,
            dialectOptions: {
                ssl: {
                    rejectUnauthorized: false
                }
            },
            pool: {
                max: 5,
                min: 0,
                acquire: 30000,
                idle: 10000
            },
            logging: console.log
        });
        try {
            await this.sequelize.authenticate();
            console.log('Connection has been established successfully.');
        } catch (error) {
            console.error('Unable to connect to the database:', error);
        }
        this.bookRepo = new BookRepository(this.sequelize, this.config);
        this.openingHourRepo = new OpeningHourRepository(this.sequelize, this.config);
        this.purchaseHistoryRepo = new PurchaseHistoryRepository(this.sequelize, this.config);
        this.storeRepo = new StoreRepository(this.sequelize, this.config);
        this.userRepo = new UserRepository(this.sequelize, this.config);

        this.bookRepo.loadRelationships();
        this.openingHourRepo.loadRelationships();
        this.purchaseHistoryRepo.loadRelationships();
        this.storeRepo.loadRelationships();
        this.userRepo.loadRelationships();
        
        await this.sequelize.sync({force: false, alter: false});
    }
}