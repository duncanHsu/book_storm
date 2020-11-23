import { Database } from "config";
import { DatabaseManager } from "database/manager";
import { BookModel } from "database/model/book";
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
