import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from "typeorm";
import { RiskAssessment } from "../../assessment/entities/risk-assessment.entity";
import { PredictionPool } from "../../prediction/entities/prediction-pool.entity";

@Entity({ name: "tokens" })
export class Token {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column({ type: "varchar", length: 42, unique: true })
  address!: string;

  @Column({ type: "integer", name: "chain_id", default: 8453 })
  chainId!: number;

  @Column({ type: "varchar", length: 42 })
  deployer!: string;

  @Column({ type: "timestamptz", name: "deployed_at" })
  deployedAt!: Date;

  @Column({ type: "boolean", name: "has_unlimited_mint", nullable: true })
  hasUnlimitedMint!: boolean | null;

  @Column({ type: "boolean", name: "has_blacklist", nullable: true })
  hasBlacklist!: boolean | null;

  @Column({ type: "boolean", name: "has_tax", nullable: true })
  hasTax!: boolean | null;

  @Column({ type: "boolean", name: "liquidity_locked", nullable: true })
  liquidityLocked!: boolean | null;

  @Column({
    type: "decimal",
    precision: 5,
    scale: 4,
    name: "top_holder_concentration",
    nullable: true,
  })
  topHolderConcentration!: number | null;

  @CreateDateColumn({ type: "timestamptz", name: "created_at" })
  createdAt!: Date;

  @UpdateDateColumn({ type: "timestamptz", name: "updated_at" })
  updatedAt!: Date;

  @OneToMany(() => RiskAssessment, (assessment) => assessment.token)
  assessments!: RiskAssessment[];

  @OneToMany(() => PredictionPool, (pool) => pool.token)
  pools!: PredictionPool[];
}
