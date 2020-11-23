import { Association, BelongsToCreateAssociationMixin, BelongsToGetAssociationMixin, BelongsToSetAssociationMixin, DataTypes, Model, Sequelize } from "sequelize";
import { StoreModel } from "./store";

export class OpeningHourModel extends Model {
    public id!: number;
    public week!: Week;
    public startMinutes!: number;
    public endMinutes!: number;
    public openMinutes!: number;

    public readonly createdAt!: Date;
    public readonly updatedAt!: Date;

    public readonly store?: StoreModel;

    public getStore!: BelongsToGetAssociationMixin<StoreModel>;
    public createStore!: BelongsToCreateAssociationMixin<StoreModel>;
    public setStore!: BelongsToSetAssociationMixin<StoreModel, number>;

    public static associations: {
        store: Association<OpeningHourModel, StoreModel>;
    };
}

export class OpeningHour {
    public static Create(sequelize: Sequelize): typeof OpeningHourModel {
        OpeningHourModel.init({
            id: {
                type: DataTypes.INTEGER,
                primaryKey: true,
                autoIncrement: true,
            },
            week: {
                type: DataTypes.INTEGER,
                allowNull: false,
            },
            startMinutes: {
                type: DataTypes.INTEGER,
                allowNull: false,
            },
            endMinutes: {
                type: DataTypes.INTEGER,
                allowNull: false,
            },
            openMinutes: {
                type: DataTypes.INTEGER,
                allowNull: false,
            },
        }, {
            tableName: 'OpeningHours',
            sequelize: sequelize,
        });
        return OpeningHourModel;
    }
}

export enum Week
{
    Mon = 1,
    Tues,
    Wed,
    Thurs,
    Fri,
    Sat,
    Sun
}