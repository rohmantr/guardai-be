import { MigrationInterface, QueryRunner } from "typeorm";
import * as fs from "fs";
import * as path from "path";

export class CreatePredictionPools20260713000003 implements MigrationInterface {
    name = 'CreatePredictionPools20260713000003';

    public async up(queryRunner: QueryRunner): Promise<void> {
        const sql = fs.readFileSync(path.join(__dirname, "20260713000003-create-prediction-pools.sql"), "utf8");
        await queryRunner.query(sql);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE IF EXISTS prediction_pools CASCADE;`);
    }
}
