import { Config } from "config";
import { OpeningHour, OpeningHourModel } from "../../database/model/openingHour";
import { Op, Sequelize } from "sequelize";
import { StoreModel } from "../../database/model/store";
import { MoreOrLess } from "../../controllers/book";

export class OpeningHourRepository {

    private sequelize: Sequelize;
    private config: Config;

    constructor(sequelize: Sequelize, config: Config) {
        this.sequelize = sequelize;
        this.config = config;
        OpeningHour.Create(this.sequelize);
    }

    public loadRelationships() {
        OpeningHourModel.belongsTo(StoreModel, { foreignKey: 'storeId', targetKey: 'id', as: 'store' });
    }

    public findById(id: number): Promise<OpeningHourModel> {
        return OpeningHourModel.findOne<OpeningHourModel>({
            where: {
                id: id
            }
        });
    }

    public findByWeekTime(week: number, time: number): Promise<OpeningHourModel[]> {
        return OpeningHourModel.findAll({
            where: {
                week: week,
                startMinutes: {
                    [Op.lte]: time
                },
                endMinutes: {
                    [Op.gte]: time
                },
            },
            include: [ OpeningHourModel.associations.store ]
        });
    }

    public findByTime(time: number): Promise<OpeningHourModel[]> {
        return OpeningHourModel.findAll({
            where: {
                startMinutes: {
                    [Op.lte]: time
                },
                endMinutes: {
                    [Op.gte]: time
                },
            },
            include: [ OpeningHourModel.associations.store ]
        });
    }

    public findByDayHours(mol: MoreOrLess, hours: number): Promise<OpeningHourModel[]> {
        const minutes = hours * 60;
        const om = (mol == MoreOrLess.More ? { [Op.gte]: minutes } : { [Op.lte]: minutes });
        
        return OpeningHourModel.findAll({
            where: {
                openMinutes: om,
            },
            include: [ OpeningHourModel.associations.store ]
        });
    }

    public getWeekFromDate(dt: Date): number {
        let week = dt.getDay();
        if (week == 0) {
            week = 7;
        }
        return week;
    }

    public getMinutesFromDate(dt: Date): number {
        const hours = dt.getHours();
        const minutes = dt.getMinutes();
        return hours * 60 + minutes;
    }
}
