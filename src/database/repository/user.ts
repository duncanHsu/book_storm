import { Config } from "config";
import { PurchaseHistoryModel } from "../../database/model/purchaseHistory";
import { User, UserModel } from "../../database/model/user";
import { Op, Sequelize } from "sequelize";

export class UserRepository {

    private sequelize: Sequelize;
    private config: Config;

    constructor(sequelize: Sequelize, config: Config) {
        this.sequelize = sequelize;
        this.config = config;
        User.Create(this.sequelize);
    }

    public loadRelationships() {
        UserModel.hasMany(PurchaseHistoryModel, { sourceKey: 'id', foreignKey: 'userId', as: 'purchaseHistory' });
    }

    public findById(id: number): Promise<UserModel> {
        return UserModel.findOne<UserModel>({
            where: {
                id: id
            }
        });
    }

    public findByUsers(userIds: number[]): Promise<UserModel[]> {
        return UserModel.findAll({
            where: {
                id: {
                    [Op.in]: userIds,
                }
            }
        });
    }

}
