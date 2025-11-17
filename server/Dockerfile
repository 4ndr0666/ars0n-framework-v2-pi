# ---- Build stage ----
FROM golang:1.21 as builder

WORKDIR /app

# Copy go mod and sum first for dependency caching
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the Go binary (replace 'main.go' with your actual entrypoint if needed)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server .

# ---- Minimal runtime stage ----
FROM alpine:3.18

WORKDIR /app
COPY --from=builder /app/server /app/server

# (Optional) If you have runtime assets, copy them:
# COPY --from=builder /app/models /app/models
# COPY --from=builder /app/nuclei /app/nuclei

EXPOSE 8080
ENTRYPOINT ["/app/server"]