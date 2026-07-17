import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  JoinColumn,
  OneToOne,
} from "typeorm";
import type { PredictionPool } from "../../prediction/entities/prediction-pool.entity";
import type { Attestation } from "../../attestation/entities/attestation.entity";

@Entity({ name: "resolution_events" })
export class ResolutionEvent {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column({ type: "uuid", name: "pool_id", unique: true })
  poolId!: string;

  @OneToOne("PredictionPool", "resolutionEvent", { onDelete: "CASCADE" })
  @JoinColumn({ name: "pool_id" })
  pool!: PredictionPool;

  @Column({ type: "boolean", name: "liquidity_pulled" })
  liquidityPulled!: boolean;

  @Column({ type: "varchar", length: 3, name: "winning_side" })
  winningSide!: "YES" | "NO";

  @Column({ type: "varchar", length: 66, name: "tx_hash" })
  txHash!: string;

  @Column({
    type: "timestamptz",
    name: "resolved_at",
    default: () => "CURRENT_TIMESTAMP",
  })
  resolvedAt!: Date;

  @OneToOne("Attestation", "resolutionEvent")
  attestation!: Attestation;
}
