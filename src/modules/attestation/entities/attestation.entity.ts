import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToOne,
  JoinColumn,
} from "typeorm";
import { ResolutionEvent } from "../../oracle/entities/resolution-event.entity";

@Entity({ name: "attestations" })
export class Attestation {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column({ type: "uuid", name: "pool_id", unique: true })
  poolId!: string;

  @OneToOne(() => ResolutionEvent, (event) => event.attestation, {
    onDelete: "CASCADE",
  })
  @JoinColumn({ name: "pool_id", referencedColumnName: "poolId" })
  resolutionEvent!: ResolutionEvent;

  @Column({ type: "varchar", length: 66, unique: true, name: "eas_uid" })
  easUid!: string;

  @Column({ type: "boolean", name: "predicted_outcome" })
  predictedOutcome!: boolean;

  @Column({ type: "boolean", name: "actual_outcome" })
  actualOutcome!: boolean;

  @Column({
    type: "timestamptz",
    name: "attested_at",
    default: () => "CURRENT_TIMESTAMP",
  })
  attestedAt!: Date;
}
