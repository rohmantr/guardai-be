import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from "typeorm";
import type { Token } from "../../token/entities/token.entity";
import type { PredictionPool } from "../../prediction/entities/prediction-pool.entity";

@Entity({ name: "risk_assessments" })
export class RiskAssessment {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column({ type: "uuid", name: "token_id" })
  tokenId!: string;

  @ManyToOne("Token", "assessments", { onDelete: "CASCADE" })
  @JoinColumn({ name: "token_id" })
  token!: Token;

  @Column({ type: "decimal", precision: 5, scale: 4 })
  probability!: number;

  @Column({ type: "text" })
  reasoning!: string;

  @Column({ type: "decimal", precision: 5, scale: 4 })
  confidence!: number;

  @Column({ type: "varchar", length: 50, name: "llm_model" })
  llmModel!: string;

  @Column({ type: "timestamptz", name: "assessed_at" })
  assessedAt!: Date;

  @CreateDateColumn({ type: "timestamptz", name: "created_at" })
  createdAt!: Date;

  @OneToMany("PredictionPool", "assessment")
  pools!: PredictionPool[];
}
