# ADR-005: Event-Driven Architecture untuk Backend

**Status:** Accepted
**Tanggal:** 13 Juli 2026

## Konteks

Proses dari deteksi token hingga settlement terdiri dari beberapa langkah independen yang bisa berjalan async.

## Keputusan

Menggunakan **event-driven architecture** dengan message queue (RabbitMQ / Redis Streams).

## Alasan

- Decoupling antara deteksi token, assessment, dan settlement
- Setiap langkah bisa di-scale independently
- Failure satu langkah tidak mengganggu langkah lain (graceful degradation)
- Event log memudahkan debugging dan replay

## Konsekuensi

- Infrastruktur tambahan (message broker)
- Eventual consistency — ada delay antara event dan aksi
- Perlu idempotency handler untuk at-least-once delivery
