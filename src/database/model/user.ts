import { Association, DataTypes, HasManyAddAssociationMixin, HasManyCountAssociationsMixin, HasManyCreateAssociationMixin, HasManyGetAssociationsMixin, HasManyHasAssociationMixin, Model, Sequelize } from "sequelize";
import { PurchaseHistoryModel } from "./purchaseHistory";

export class UserModel extends Model {
    public id!: number;
    public name!: string;
    public cashBalance!: number;

    public readonly createdAt!: Date;
    public readonly updatedAt!: Date;

    public readonly purchaseHistory?: PurchaseHistoryModel[];

    public getPurchaseHistory!: HasManyGetAssociationsMixin<PurchaseHistoryModel>;
    public addPurchaseHistory!: HasManyAddAssociationMixin<PurchaseHistoryModel, number>;
    public hasPurchaseHistory!: HasManyHasAssociationMixin<PurchaseHistoryModel, number>;
    public countPurchaseHistory!: HasManyCountAssociationsMixin;
    public createPurchaseHistory!: HasManyCreateAssociationMixin<PurchaseHistoryModel>;

    public static associations: {
        purchaseHistory: Association<UserModel, PurchaseHistoryModel>;
    };
}

export class User {
    public static Create(sequelize: Sequelize): typeof UserModel {
        UserModel.init({
            id: {
                type: DataTypes.INTEGER,
                primaryKey: true,
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
            tableName: 'Users',
            sequelize: sequelize,
        });
        return UserModel;
    }
}
