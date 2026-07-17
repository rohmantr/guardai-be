import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from "typeorm";
import { PredictionPool } from "./prediction-pool.entity";

@Entity({ name: "positions" })
export class Position {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column({ type: "uuid", name: "pool_id" })
  poolId!: string;

  @ManyToOne(() => PredictionPool, (pool) => pool.positions, {
    onDelete: "CASCADE",
  })
  @JoinColumn({ name: "pool_id" })
  pool!: PredictionPool;

  @Column({ type: "varchar", length: 42, name: "user_address" })
  userAddress!: string;

  @Column({ type: "varchar", length: 3 })
  side!: "YES" | "NO";

  @Column({ type: "numeric", precision: 40, scale: 0 })
  amount!: string;

  @Column({ type: "boolean", default: false })
  claimed!: boolean;

  @CreateDateColumn({ type: "timestamptz", name: "created_at" })
  createdAt!: Date;
}
