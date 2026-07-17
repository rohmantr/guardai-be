import { MigrationInterface, QueryRunner } from "typeorm";
import * as fs from "fs";
import * as path from "path";

export class CreateAttestations20260713000006 implements MigrationInterface {
  name = "CreateAttestations20260713000006";

  public async up(queryRunner: QueryRunner): Promise<void> {
    const sql = fs.readFileSync(
      path.join(__dirname, "20260713000006-create-attestations.sql"),
      "utf8",
    );
    await queryRunner.query(sql);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS attestations CASCADE;`);
  }
}
