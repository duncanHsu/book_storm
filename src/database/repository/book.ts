import { Config } from "config";
import { Book, BookModel } from "../../database/model/book";
import { StoreModel } from "../../database/model/store";
import { Op, Sequelize } from "sequelize";

export class BookRepository {

    private sequelize: Sequelize;
    private config: Config;

    constructor(sequelize: Sequelize, config: Config) {
        this.sequelize = sequelize;
        this.config = config;
        Book.Create(this.sequelize);
    }

    public loadRelationships() {
        BookModel.belongsTo(StoreModel, { foreignKey: 'storeId', targetKey: 'id', as: 'store' });
    }

    public findById(id: number): Promise<BookModel> {
        return BookModel.findOne<BookModel>({
            where: {
                id: id
            }
        });
    }

    public findByPrice(priceRange: number[], sortBy: 'price' | 'alphabetically'): Promise<BookModel[]> {
        const order = (sortBy == 'alphabetically' ? 'name' : sortBy);
        return BookModel.findAll({
            where: {
                price: {
                    [Op.between]: priceRange
                }
            },
            order: [[order, 'ASC']]
        });
    }

    public search(value: string): Promise<BookModel[]> {
        return BookModel.findAll<BookModel>({
            where: {
                name: {
                    [Op.iLike]: `%${value}%`
                }
            }
        });
    }

}
