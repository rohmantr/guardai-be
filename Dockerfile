FROM oven/bun:1-alpine

WORKDIR /app

# Install dependencies
COPY package.json bun.lockb tsconfig.json ./
RUN bun install --frozen-lockfile

# Copy application source
COPY . .

# Expose port
EXPOSE 3000

# Run the app directly using bun to support TS and dynamic imports
CMD ["bun", "src/main.ts"]
