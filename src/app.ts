import * as bodyParser from "body-parser";
import * as cookieParser from "cookie-parser";
import * as express from "express";
import * as session from "express-session";
import * as logger from "morgan";
import * as path from "path";
import { Config } from "./config";
import { BookController } from "./controllers/book";
import { StoreController } from "./controllers/store";
import { UserController } from "./controllers/user";
import { DatabaseManager } from "./database/manager";
import flash = require('connect-flash');

class App {
    private env: string;
    private config: Config;

    public app: express.Application;

    private dbManager: DatabaseManager;
    public bookController: BookController;
    public storeController: StoreController;
    public userController: UserController;
    
    constructor() {
        this.app = express();
        this.init();
    }

    private async init(): Promise<void> {
        await this.initConfig();
        this.initControllers();
        this.initRoutes();
    }

    private async initConfig(): Promise<void> {
        this.env = process.env.NODE_ENV || 'development';
        console.log(this.env);
        this.config = require(__dirname + '/config.json')[this.env];

        this.app.set("views", path.join(__dirname, "./views"));
        this.app.set("view engine", "ejs");

        this.app.use(logger('dev'));
        this.app.use(cookieParser());
        this.app.use(bodyParser.json());
        this.app.use(bodyParser.urlencoded({ extended: false }));
        this.app.use(express.static(path.join(__dirname, "./public")));
        this.app.use(flash());
        this.app.use(session({ 
            secret: 'secret',
            resave: false,
            saveUninitialized: false
        }));

        this.dbManager = new DatabaseManager(this.config);
        await this.dbManager.load();
    }

    private initControllers(): void {
        this.bookController = new BookController(this.dbManager);
        this.storeController = new StoreController(this.dbManager);
        this.userController = new UserController(this.dbManager);
    }

    private initRoutes(): void {
        this.app.get("/", this.userController.home);
        this.app.get("/api/", this.userController.root);

        this.app.post("/api/store/open/datetime", this.storeController.openByDatetime);
        this.app.post("/api/store/open/dayOfWeek", this.storeController.openDayOfWeek);
        this.app.post("/api/store/open/hours", this.storeController.openHours);
        this.app.post("/api/store/books/numberOfBooks", this.storeController.numberOfBooks);
        this.app.post("/api/store/numberOfBooksWithinPriceRange", this.storeController.numberOfBooksWithinPriceRange);
        this.app.post("/api/store/books/search", this.storeController.search);
        this.app.post("/api/store/popular", this.storeController.popular);

        this.app.post("/api/book/priceRange", this.bookController.priceRange);
        this.app.post("/api/book/purchase", this.bookController.purchase);
        
        this.app.post("/api/user/top/totalNumberDollarOfTransactions", this.userController.totalNumberDollarOfTransactions);
        this.app.post("/api/user/transaction/total", this.userController.transactionTotal);
        this.app.post("/api/user/edit/store", this.storeController.edit);
        this.app.post("/api/user/edit/book", this.bookController.edit);
        this.app.post("/api/user/edit/user", this.userController.edit);
        this.app.post("/api/user/transaction/numberOfUsers", this.userController.transactionNumberOfUsers);
        

    }

}

export default new App().app;