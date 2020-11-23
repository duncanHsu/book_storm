import { Association, BelongsToCreateAssociationMixin, BelongsToGetAssociationMixin, BelongsToSetAssociationMixin, DataTypes, Model, Sequelize } from "sequelize";
import { UserModel } from "./user";

export class PurchaseHistoryModel extends Model {
    public id!: number;
    public storeName!: string;
    public bookName!: string;
    public transactionAmount!: number;
    public transactionDate!: Date;

    public readonly createdAt!: Date;
    public readonly updatedAt!: Date;

    public readonly user?: UserModel;

    public getUser!: BelongsToGetAssociationMixin<UserModel>;
    public createUser!: BelongsToCreateAssociationMixin<UserModel>;
    public setUser!: BelongsToSetAssociationMixin<UserModel, number>;

    public static associations: {
        user: Association<PurchaseHistoryModel, UserModel>;
    };
}

export class PurchaseHistory {
    public static Create(sequelize: Sequelize): typeof PurchaseHistoryModel {
        PurchaseHistoryModel.init({
            id: {
                type: DataTypes.INTEGER,
                primaryKey: true,
                autoIncrement: true,
            },
            storeName: {
                type: DataTypes.STRING,
                allowNull: false,
            },
            bookName: {
                type: DataTypes.STRING,
                allowNull: false,
            },
            transactionAmount: {
                type: DataTypes.FLOAT,
                allowNull: false,
            },
            transactionDate: {
                type: DataTypes.DATE,
                allowNull: false,
            },
        }, {
            tableName: 'PurchaseHistory',
            sequelize: sequelize,
        });
        return PurchaseHistoryModel;
    }
}
