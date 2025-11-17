FROM golang:1.21 AS build
WORKDIR /src
RUN git clone --depth 1 https://github.com/projectdiscovery/httpx.git
WORKDIR /src/httpx/cmd/httpx
RUN CGO_ENABLED=0 go build -o /httpx .

FROM alpine:3.19
COPY --from=build /httpx /usr/bin/httpx
ENTRYPOINT ["/usr/bin/httpx"]