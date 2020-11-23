import { DatabaseManager } from "database/manager";
import { PurchaseHistoryModel } from "database/model/purchaseHistory";
import { UserModel } from "database/model/user";
import { Request, Response } from "express";

export class UserController {
    private db: DatabaseManager;

    constructor(db: DatabaseManager) {
        this.db = db;
    }

    public home = (req: Request, res: Response) => {
        res.send("<h1>Hi Kdan</h1>");
    }

    public root = (req: Request, res: Response) => {
        res.json();
    }

    public totalNumberDollarOfTransactions = (req: Request, res: Response) => {
        const dateRange: Date[] = req.body.dateRange;
        if (dateRange.length != 2) {
            return res.status(500).json();
        }
        dateRange[0] = new Date(dateRange[0]);
        dateRange[1] = new Date(dateRange[1]);
        const top: number = req.body.top;
        let userIds: number[] = [];
        this.db.purchaseHistoryRepo.findByDateRange(dateRange).then((models: PurchaseHistoryModel[]) => {
            const userAmountMap = new Map<number, number>();
            for (const model of models) {
                let amount = 0;
                if (userAmountMap.has(model.user.id)) {
                    amount = userAmountMap.get(model.user.id);
                }
                userAmountMap.set(model.user.id, amount + model.transactionAmount);
            }
            let data = [];
            userAmountMap.forEach((value, key) => {
                data.push({id: key, amount: value});
            });
            data = data.sort((a, b) => {
                return b.amount - a.amount;
            });
            userIds = data.map<number>((value) => {
                return value.id;
            });
            userIds = userIds.slice(0, top);
            return this.db.userRepo.findByUsers(userIds);
        }).then((models: UserModel[]) => {
            const result = [];
            for (const id of userIds) {
                const model = this.findById(id, models);
                result.push({id: model.id, name: model.name, cashBalance: model.cashBalance, createdAt: model.createdAt, updatedAt: model.updatedAt});
            }
            res.json(result);
        });
    };

    public transactionTotal = (req: Request, res: Response) => {
        const dateRange: Date[] = req.body.dateRange;
        if (dateRange.length != 2) {
            return res.status(500).json();
        }
        dateRange[0] = new Date(dateRange[0]);
        dateRange[1] = new Date(dateRange[1]);
        this.db.purchaseHistoryRepo.findByDateRange(dateRange).then((models: PurchaseHistoryModel[]) => {
            const transactionCount = models.length;
            let transactionAmount = 0;
            for (const model of models) {
                transactionAmount += model.transactionAmount;
            }
            res.json({count: transactionCount, amount: transactionAmount});
        });
    };

    public transactionNumberOfUsers = (req: Request, res: Response) => {
        const dateRange: Date[] = req.body.dateRange;
        if (dateRange.length != 2) {
            return res.status(500).json();
        }
        dateRange[0] = new Date(dateRange[0]);
        dateRange[1] = new Date(dateRange[1]);
        const aboveOrBelow: AboveOrBelow = req.body.aboveOrBelow;
        const value: number = req.body.value;
        this.db.purchaseHistoryRepo.findByDateRange(dateRange).then((models: PurchaseHistoryModel[]) => {
            const userCountMap = new Map<number, number>();
            for (const model of models) {
                if (!userCountMap.has(model.user.id)) {
                    userCountMap.set(model.user.id, 1);
                } else {
                    let count = userCountMap.get(model.user.id);
                    userCountMap.set(model.user.id, count + 1);
                }
            }
            const userCounts = [];
            userCountMap.forEach((count, usrId) => {
                if (aboveOrBelow == AboveOrBelow.Above) {
                    if (count >= value) {
                        userCounts.push({userId: usrId, count: count});
                    }
                } else {
                    if (count <= value) {
                        userCounts.push({userId: usrId, count: count});
                    }
                }
            });
            res.json({numberOfUsers: userCounts.length});
        });
    };
    
    public edit = (req: Request, res: Response) => {
        const id: number = req.body.id;
        const new_name: string = req.body.new_name;
        this.db.userRepo.findById(id).then((model: UserModel) => {
            if (!model) {
                return res.status(500).json();
            }
            model.name = new_name;
            return model.save();
        }).then((model: UserModel) => {
            res.json(model);
        });
    }

    private findById(id: number, data: UserModel[]): UserModel {
        for (const iterator of data) {
            if (id == iterator.id) {
                return iterator;
            }
        }
        return null;
    }
}

export enum AboveOrBelow
{
    Above = 'above',
    Below = 'below',
}
