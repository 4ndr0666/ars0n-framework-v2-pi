## ---------------------------------------------------------
## Production-Ready Multi-Stage Build for Go API Server
## ---------------------------------------------------------

# ---------- Stage 1: Builder ----------
FROM golang:1.21 AS build

# Create working directory
WORKDIR /app

# Enable Go modules
ENV GO111MODULE=on

# Copy go.mod and go.sum first (for better caching)
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the rest of the server source
COPY . .

# Build static Go binary (no CGO)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server .

# ---------- Stage 2: Runtime ----------
FROM alpine:3.19

# Install certs for HTTPS requests
RUN apk add --no-cache ca-certificates

WORKDIR /app

# Copy compiled Go binary from builder
COPY --from=build /app/server /app/server

# Optional: copy runtime assets if your server needs them:
# COPY --from=build /app/models /app/models
# COPY --from=build /app/nuclei /app/nuclei

# Expose API port (matches your Go server config)
EXPOSE 8443

# Launch the Go server
ENTRYPOINT ["/app/server"]