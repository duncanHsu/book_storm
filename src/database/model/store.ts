import { Association, DataTypes, HasManyAddAssociationMixin, HasManyCountAssociationsMixin, HasManyCreateAssociationMixin, HasManyGetAssociationsMixin, HasManyHasAssociationMixin, Model, Sequelize } from "sequelize";
import { BookModel } from "./book";
import { OpeningHourModel } from "./openingHour";

export class StoreModel extends Model {
    public id!: number;
    public name!: string;
    public cashBalance!: number;

    public readonly createdAt!: Date;
    public readonly updatedAt!: Date;

    public readonly books?: BookModel[];
    public readonly openingHours?: OpeningHourModel[];

    public getBooks!: HasManyGetAssociationsMixin<BookModel>;
    public addBook!: HasManyAddAssociationMixin<BookModel, number>;
    public hasBook!: HasManyHasAssociationMixin<BookModel, number>;
    public countBooks!: HasManyCountAssociationsMixin;
    public createBook!: HasManyCreateAssociationMixin<BookModel>;

    public getOpeningHours!: HasManyGetAssociationsMixin<OpeningHourModel>;
    public addOpeningHour!: HasManyAddAssociationMixin<OpeningHourModel, number>;
    public hasOpeningHour!: HasManyHasAssociationMixin<OpeningHourModel, number>;
    public countOpeningHours!: HasManyCountAssociationsMixin;
    public createOpeningHour!: HasManyCreateAssociationMixin<OpeningHourModel>;

    public static associations: {
        books: Association<StoreModel, BookModel>;
        openingHours: Association<StoreModel, OpeningHourModel>;
    };
}

export class Store {
    public static Create(sequelize: Sequelize): typeof StoreModel {
        StoreModel.init({
            id: {
                type: DataTypes.INTEGER,
                primaryKey: true,
                autoIncrement: true,
            },
            name: {
                type: DataTypes.STRING,
                allowNull: false,
            },
            cashBalance: {
                type: DataTypes.FLOAT,
                allowNull: false,
            },
        }, {
            tableName: 'Stores',
            sequelize: sequelize,
        });
        return StoreModel;
    }
}
