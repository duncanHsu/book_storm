import { Association, BelongsToCreateAssociationMixin, BelongsToGetAssociationMixin, BelongsToSetAssociationMixin, DataTypes, Model, Sequelize } from "sequelize";
import { StoreModel } from "./store";

export class BookModel extends Model {
    public id!: number;
    public name!: string;
    public price!: number;

    public readonly createdAt!: Date;
    public readonly updatedAt!: Date;

    public readonly store?: StoreModel;

    public getStore!: BelongsToGetAssociationMixin<StoreModel>;
    public createStore!: BelongsToCreateAssociationMixin<StoreModel>;
    public setStore!: BelongsToSetAssociationMixin<StoreModel, number>;

    public static associations: {
        store: Association<BookModel, StoreModel>;
    };
}

export class Book {
    public static Create(sequelize: Sequelize): typeof BookModel {
        BookModel.init({
            id: {
                type: DataTypes.INTEGER,
                primaryKey: true,
                autoIncrement: true,
            },
            name: {
                type: DataTypes.STRING,
                allowNull: false,
            },
            price: {
                type: DataTypes.FLOAT,
                allowNull: false,
            },
        }, {
            tableName: 'Books',
            sequelize: sequelize,
        });
        return BookModel;
    }
}
