import { MigrationInterface, QueryRunner } from "typeorm";
import * as fs from "fs";
import * as path from "path";

export class CreateRiskAssessments20260713000002 implements MigrationInterface {
  name = "CreateRiskAssessments20260713000002";

  public async up(queryRunner: QueryRunner): Promise<void> {
    const sql = fs.readFileSync(
      path.join(__dirname, "20260713000002-create-risk-assessments.sql"),
      "utf8",
    );
    await queryRunner.query(sql);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS risk_assessments CASCADE;`);
  }
}
