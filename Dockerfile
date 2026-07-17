# Stage 1: Build the statically linked Go binary
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy dependency files
COPY backend/go.mod backend/go.sum ./
RUN go mod download

# Copy backend source code
COPY backend/ .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Stage 2: Final minimal execution container
FROM alpine:3.19

RUN apk --no-cache add ca-certificates

WORKDIR /app

COPY --from=builder /app/main .

EXPOSE 3000

CMD ["./main"]
