import { Config } from "config";
import { PurchaseHistory, PurchaseHistoryModel } from "../../database/model/purchaseHistory";
import { Op, Sequelize } from "sequelize";
import { UserModel } from "../../database/model/user";

export class PurchaseHistoryRepository {

    private sequelize: Sequelize;
    private config: Config;

    constructor(sequelize: Sequelize, config: Config) {
        this.sequelize = sequelize;
        this.config = config;
        PurchaseHistory.Create(this.sequelize);
    }

    public loadRelationships() {
        PurchaseHistoryModel.belongsTo(UserModel, { foreignKey: 'userId', targetKey: 'id', as: 'user' });
    }

    public create(storeName: string, bookName: string, transactionAmount: number, transactionDate: Date): Promise<PurchaseHistoryModel> {
        return PurchaseHistoryModel.create({storeName: storeName, bookName: bookName, transactionAmount: transactionAmount, transactionDate});
    }

    public findById(id: number): Promise<PurchaseHistoryModel> {
        return PurchaseHistoryModel.findOne<PurchaseHistoryModel>({
            where: {
                id: id
            }
        });
    }

    public findByDateRange(dateRange: Date[]): Promise<PurchaseHistoryModel[]> {
        console.log(dateRange);
        const dr = [dateRange[0].toISOString(), dateRange[1].toISOString()];
        return PurchaseHistoryModel.findAll({
            where: {
                transactionDate: {
                    [Op.between]: dr
                }
            },
            include: [ PurchaseHistoryModel.associations.user ]
        });
    }

    public groupByNumberForStore(limit: number): Promise<CountData[]> {
        return PurchaseHistoryModel.findAll({
            attributes: ['storeName', [Sequelize.fn('COUNT', Sequelize.col('transactionAmount')), 'count']],
            order: [ ['count', 'DESC'] ],
            group: ['storeName'],
            limit: limit,
            raw: true,
        });
    }

    public groupByDollarForStore(limit: number): Promise<SumData[]> {
        return PurchaseHistoryModel.findAll({
            attributes: ['storeName', [Sequelize.fn('SUM', Sequelize.col('transactionAmount')), 'sum']],
            order: Sequelize.literal('sum DESC'),
            group: ['storeName'],
            limit: limit,
            raw: true,
        });
    }

}

export class CountData
{
    public storeName: string;
    public count: number;
}

export class SumData
{
    public storeName: string;
    public sum: number;
}
