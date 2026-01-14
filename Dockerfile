# =========================
# Stage 1: Build the Go binary
# =========================
FROM golang:1.25-alpine AS builder

# Install git (sometimes needed for Go modules)
RUN apk add --no-cache git ca-certificates

WORKDIR /src

# Copy go.mod/go.sum first (for caching)
COPY much-to-do/Server/MuchToDo/go.mod much-to-do/Server/MuchToDo/go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY much-to-do/Server/MuchToDo/ ./

# Build the binary
# We compile the cmd/api folder because it contains main.go
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/muchtodo ./cmd/api


# =========================
# Stage 2: Run the binary (small image)
# =========================
FROM alpine:3.20

# Add certificates + curl (curl is needed for HEALTHCHECK)
RUN apk add --no-cache ca-certificates curl && update-ca-certificates

# Create a non-root user (security best practice)
RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/muchtodo /app/muchtodo

# Switch to non-root user
USER app

# App runs on 8080 (confirmed from assessment brief)
EXPOSE 8080

# Healthcheck endpoint
HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD curl -fsS http://localhost:8080/health || exit 1

# Start the app
CMD ["/app/muchtodo"]

