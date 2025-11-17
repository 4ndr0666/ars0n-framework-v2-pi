FROM golang:1.21 AS build
WORKDIR /src
RUN git clone --depth 1 https://github.com/projectdiscovery/shuffledns.git
WORKDIR /src/shuffledns/cmd/shuffledns
RUN CGO_ENABLED=0 go build -o /shuffledns .

FROM alpine:3.19
COPY --from=build /shuffledns /usr/bin/shuffledns
ENTRYPOINT ["/usr/bin/shuffledns"]