import { Config } from "config";
import { BookModel } from "../../database/model/book";
import { Store, StoreModel } from "../../database/model/store";
import { Op, Sequelize } from "sequelize";
import { OpeningHourModel } from "../../database/model/openingHour";
import { MoreOrLess } from "../../controllers/book";


export class StoreRepository {

    private sequelize: Sequelize;
    private config: Config;

    constructor(sequelize: Sequelize, config: Config) {
        this.sequelize = sequelize;
        this.config = config;
        Store.Create(this.sequelize);
    }

    public loadRelationships() {
        StoreModel.hasMany(BookModel, { sourceKey: 'id', foreignKey: 'storeId', as: 'books' });
        StoreModel.hasMany(OpeningHourModel, { sourceKey: 'id', foreignKey: 'storeId', as: 'openingHours' });
    }

    public findById(id: number): Promise<StoreModel> {
        return StoreModel.findOne<StoreModel>({
            where: {
                id: id
            }
        });
    }

    public findByName(name: string): Promise<StoreModel> {
        return StoreModel.findOne<StoreModel>({
            where: {
                name: name
            }
        });
    }

    public findWithWeek(): Promise<StoreModel[]> {
        return StoreModel.findAll<StoreModel>({
            include: [ StoreModel.associations.openingHours ],
        });
    }

    public async findByNumberOfBooks(mol: MoreOrLess, value: number): Promise<StoreModel[]> {
        const sms: StoreModel[] = await StoreModel.findAll({
            include: [ StoreModel.associations.books ]
        });
        let storeMap = new Map<number, StoreModel>();
        for (const sm of sms) {
            const count = sm.books.length;
            if (mol == MoreOrLess.More) {
                if (count >= value) {
                    storeMap.set(sm.id, sm);
                }
            } else {
                if (count <= value) {
                    storeMap.set(sm.id, sm);
                }
            }
        }
        return Array.from(storeMap.values());
    }

    public async findByNumberOfBooksWithinPriceRange(priceRange: number[], mol: MoreOrLess, value: number): Promise<StoreModel[]> {
        const sms: StoreModel[] = await StoreModel.findAll({
            include: [ {
                association: StoreModel.associations.books,
                where: {
                    price: {
                        [Op.between]: priceRange
                    }
                }
            }]
        });
        let storeMap = new Map<number, StoreModel>();
        for (const sm of sms) {
            const count = sm.books.length;
            if (mol == MoreOrLess.More) {
                if (count >= value) {
                    storeMap.set(sm.id, sm);
                }
            } else {
                if (count <= value) {
                    storeMap.set(sm.id, sm);
                }
            }
        }
        return Array.from(storeMap.values());
    }

    public search(value: string): Promise<StoreModel[]> {
        return StoreModel.findAll<StoreModel>({
            where: {
                name: {
                    [Op.iLike]: `%${value}%`
                }
            }
        });
    }

}
