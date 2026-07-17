import { MigrationInterface, QueryRunner } from "typeorm";
import * as fs from "fs";
import * as path from "path";

export class CreatePositions20260713000004 implements MigrationInterface {
  name = "CreatePositions20260713000004";

  public async up(queryRunner: QueryRunner): Promise<void> {
    const sql = fs.readFileSync(
      path.join(__dirname, "20260713000004-create-positions.sql"),
      "utf8",
    );
    await queryRunner.query(sql);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS positions CASCADE;`);
  }
}
