import { Dialect } from "sequelize/types";

export interface Config {
    database: Database;
}

export interface Database {
    host: string;
    port: number;
    name: string;
    username: string;
    password: string;
    dialect: Dialect;
}
