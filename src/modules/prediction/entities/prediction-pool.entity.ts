import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToMany,
  OneToOne,
} from "typeorm";
import { Token } from "../../token/entities/token.entity";
import { RiskAssessment } from "../../assessment/entities/risk-assessment.entity";
import { Position } from "./position.entity";
import { ResolutionEvent } from "../../oracle/entities/resolution-event.entity";

@Entity({ name: "prediction_pools" })
export class PredictionPool {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column({ type: "uuid", name: "token_id" })
  tokenId!: string;

  @ManyToOne(() => Token, (token) => token.pools, { onDelete: "CASCADE" })
  @JoinColumn({ name: "token_id" })
  token!: Token;

  @Column({ type: "uuid", name: "assessment_id" })
  assessmentId!: string;

  @ManyToOne(() => RiskAssessment, (assessment) => assessment.pools, {
    onDelete: "RESTRICT",
  })
  @JoinColumn({ name: "assessment_id" })
  assessment!: RiskAssessment;

  @Column({
    type: "varchar",
    length: 42,
    unique: true,
    name: "contract_address",
  })
  contractAddress!: string;

  @Column({
    type: "numeric",
    precision: 40,
    scale: 0,
    name: "yes_pool_amount",
    default: "0",
  })
  yesPoolAmount!: string;

  @Column({
    type: "numeric",
    precision: 40,
    scale: 0,
    name: "no_pool_amount",
    default: "0",
  })
  noPoolAmount!: string;

  @Column({ type: "varchar", length: 20, default: "active" })
  status!: "active" | "resolved" | "expired";

  @Column({ type: "timestamptz" })
  deadline!: Date;

  @CreateDateColumn({ type: "timestamptz", name: "created_at" })
  createdAt!: Date;

  @Column({ type: "timestamptz", name: "resolved_at", nullable: true })
  resolvedAt!: Date | null;

  @OneToMany(() => Position, (position) => position.pool)
  positions!: Position[];

  @OneToOne(() => ResolutionEvent, (event) => event.pool)
  resolutionEvent!: ResolutionEvent;
}
