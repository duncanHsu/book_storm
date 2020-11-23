import { DatabaseManager } from "database/manager";
import { OpeningHourModel } from "database/model/openingHour";
import { StoreModel } from "database/model/store";
import { CountData, SumData } from "database/repository/purchaseHistory";
import { Request, Response } from "express";
import * as bm25 from 'wink-bm25-text-search';
import * as nlp from 'wink-nlp-utils';
import { DayOrWeek, MoreOrLess } from "./book";

export class StoreController {
    private db: DatabaseManager;
    private engine = bm25();
    private pipe = [
        nlp.string.lowerCase,
        nlp.string.tokenize0,
        nlp.tokens.stem,
        nlp.tokens.removeWords,
        nlp.tokens.propagateNegations
      ];

    constructor(db: DatabaseManager) {
        this.db = db;
    }

    public openByDatetime = (req: Request, res: Response) => {
        const dt = new Date(req.body.datetime);
        const week = this.db.openingHourRepo.getWeekFromDate(dt);
        const minutes = this.db.openingHourRepo.getMinutesFromDate(dt);
        this.db.openingHourRepo.findByWeekTime(week, minutes).then((models: OpeningHourModel[]) => {
            const stores = models.map(o => o.store);
            res.json(stores);
        });
    };

    public openDayOfWeek = (req: Request, res: Response) => {
        const dt = new Date(Date.parse(req.body.time));
        const minutes = this.db.openingHourRepo.getMinutesFromDate(dt);
        this.db.openingHourRepo.findByTime(minutes).then((models: OpeningHourModel[]) => {
            let storeMap = new Map<number, StoreModel>();
            for (const model of models) {
                const store = model.store;
                storeMap.set(store.id, store);
            }
            res.json(Array.from(storeMap.values()));
        });
    };
    
    public openHours = (req: Request, res: Response) => {
        const dayOrWeek: DayOrWeek = req.body.dayOrWeek;
        const moreOrLess: MoreOrLess = req.body.moreOrLess;
        if (dayOrWeek != DayOrWeek.Day && dayOrWeek != DayOrWeek.Week) {
            return res.status(500).json();
        }
        if (moreOrLess != MoreOrLess.More && moreOrLess != MoreOrLess.Less) {
            return res.status(500).json();
        }
        const hours: number = req.body.hours;
        if (dayOrWeek == DayOrWeek.Day) {
            this.db.openingHourRepo.findByDayHours(moreOrLess, hours).then((models: OpeningHourModel[]) => {
                let storeMap = new Map<number, StoreModel>();
                for (const model of models) {
                    const store = model.store;
                    storeMap.set(store.id, store);
                }
                res.json(Array.from(storeMap.values()));
            });
            return;
        }
        this.db.storeRepo.findWithWeek().then((models: StoreModel[]) => {
            const stores = [];
            for (const model of models) {
                let minutes = 0;
                for (const oh of model.openingHours) {
                    minutes += oh.openMinutes;
                }
                if (moreOrLess == MoreOrLess.More) {
                    if (minutes >= hours * 60) {
                        stores.push({id: model.id, name: model.name, cashBalance: model.cashBalance, createdAt: model.createdAt, updatedAt: model.updatedAt});
                    }
                } else {
                    if (minutes <= hours * 60) {
                        stores.push({id: model.id, name: model.name, cashBalance: model.cashBalance, createdAt: model.createdAt, updatedAt: model.updatedAt});
                    }
                }
            }
            res.json(stores);
        });
    };

    public numberOfBooks = (req: Request, res: Response) => {
        const moreOrLess: MoreOrLess = req.body.moreOrLess;
        if (moreOrLess != MoreOrLess.More && moreOrLess != MoreOrLess.Less) {
            return res.status(500).json();
        }
        const value: number = req.body.value;
        this.db.storeRepo.findByNumberOfBooks(moreOrLess, value).then((models: StoreModel[]) => {
            const result = [];
            for (const model of models) {
                result.push({id: model.id, name: model.name, cashBalance: model.cashBalance, createdAt: model.createdAt, updatedAt: model.updatedAt});
            }
            res.json(result);
        });
    };
    
    public numberOfBooksWithinPriceRange = (req: Request, res: Response) => {
        const priceRange: number[] = req.body.priceRange;
        const moreOrLess: MoreOrLess = req.body.moreOrLess;
        if (moreOrLess != MoreOrLess.More && moreOrLess != MoreOrLess.Less) {
            return res.status(500).json();
        }
        const value: number = req.body.value;
        this.db.storeRepo.findByNumberOfBooksWithinPriceRange(priceRange, moreOrLess, value).then((models: StoreModel[]) => {
            const result = [];
            for (const model of models) {
                result.push({id: model.id, name: model.name, cashBalance: model.cashBalance, createdAt: model.createdAt, updatedAt: model.updatedAt});
            }
            res.json(result);
        });
    };

    public search = (req: Request, res: Response) => {
        const target: 'store' | 'book' = req.body.target;
        const keyword: string = req.body.keyword;
        this.db.storeRepo.search(keyword).then((models: StoreModel[]) => {
            this.engine.reset();
            this.engine.defineConfig( { fldWeights: { title: 1, body: 2 } } );
            this.engine.definePrepTasks( this.pipe );
            let i = 0;
            for (const model of models) {
                console.log(i, model.name);
                this.engine.addDoc( {title: model.name, body: model.name}, i++ );
            }
            this.engine.consolidate();
            const searchResults = this.engine.search(keyword);
            console.log(searchResults);
            const stMap = new Map<number, StoreModel>();
            for (const iterator of searchResults) {
                const i = <number>iterator[0];
                const model = models[i];
                stMap.set(model.id, model);
            }
            for (const model of models) {
                if (!stMap.has(model.id)) {
                    stMap.set(model.id, model);
                }
            }
            return res.json(Array.from(stMap.values()));
        });
    }

    public edit = (req: Request, res: Response) => {
        const id: number = req.body.id;
        const new_name: string = req.body.new_name;
        this.db.storeRepo.findById(id).then((model: StoreModel) => {
            if (!model) {
                return res.status(500).json();
            }
            model.name = new_name;
            return model.save();
        }).then((model: StoreModel) => {
            res.json(model);
        });
    }

    public popular = (req: Request, res: Response) => {
        const by: 'number' | 'dollar' = req.body.by;
        if (by != 'number' && by != 'dollar') {
            return res.status(500).json();
        }
        if (by == 'dollar') {
            this.db.purchaseHistoryRepo.groupByDollarForStore(1).then((sds: SumData[]) => {
                if (sds.length == 0) {
                    return Promise.reject();
                }
                const sd = sds[0];
                return this.db.storeRepo.findByName(sd.storeName);
            }).then((model: StoreModel) => {
                res.json(model);
            }).catch((reason) => {
                return res.status(500).json(); 
            });
            return;
        }
        this.db.purchaseHistoryRepo.groupByNumberForStore(1).then((cds: CountData[]) => {
            if (cds.length == 0) {
                return Promise.reject();
            }
            const cd = cds[0];
            return this.db.storeRepo.findByName(cd.storeName);
        }).then((model: StoreModel) => {
            res.json(model);
        }).catch((reason) => {
            return res.status(500).json(); 
        });
    }

    
}
