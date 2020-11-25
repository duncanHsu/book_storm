import { DatabaseManager } from "database/manager";
import { BookModel } from "database/model/book";
import { PurchaseHistoryModel } from "database/model/purchaseHistory";
import { StoreModel } from "database/model/store";
import { UserModel } from "database/model/user";
import { Request, Response } from "express";

export class BookController {
    private db: DatabaseManager;

    constructor(db: DatabaseManager) {
        this.db = db;
    }

    public priceRange = (req: Request, res: Response) => {
        const priceRange: number[] = req.body.priceRange;
        const sortBy: 'price' | 'alphabetically' = req.body.sortBy;
        if (sortBy != 'price' && sortBy != 'alphabetically') {
            return res.status(500).json();
        }
        this.db.bookRepo.findByPrice(priceRange, sortBy).then((models: BookModel[]) => {
            res.json(models);
        });
    };

    public edit = (req: Request, res: Response) => {
        const id: number = req.body.id;
        const new_name: string = req.body.new_name;
        const new_price: number = req.body.new_price;
        this.db.bookRepo.findById(id).then((model: BookModel) => {
            if (!model) {
                return res.status(500).json();
            }
            model.name = new_name;
            model.price = new_price;
            return model.save();
        }).then((model: BookModel) => {
            res.json(model);
        });
    }

    public purchase = (req: Request, res: Response) => {
        const userId: number = req.body.user;
        const store: string = req.body.store;
        const book: string = req.body.book;

        let sm: StoreModel;
        let bm: BookModel;
        this.db.storeRepo.findByName(store).then((model: StoreModel) => {
            if (!model) {
                return Promise.reject();
            }
            sm = model;
            return this.db.bookRepo.findByName(book);
        }).then((model: BookModel) => {
            if (!model) {
                return Promise.reject();
            }
            bm = model;
            return this.db.userRepo.findById(userId);
        }).then((model: UserModel) => {
            if (!model) {
                return Promise.reject();
            }
            return model.createPurchaseHistory({storeName: sm.name, bookName: bm.name, transactionAmount: bm.price, transactionDate: new Date()});
        }).then((model: PurchaseHistoryModel) => {
            res.json(model);
        }).catch((reasion: any) => {
            return res.status(500).json();
        });
    }
}

export enum DayOrWeek
{
    Day = 'day',
    Week = 'week',
}

export enum MoreOrLess
{
    More = 'more',
    Less = 'less',
}
