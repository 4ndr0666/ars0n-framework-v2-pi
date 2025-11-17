FROM golang:1.21 AS build
WORKDIR /src
RUN git clone --depth 1 https://github.com/ffuf/ffuf.git
WORKDIR /src/ffuf
RUN CGO_ENABLED=0 go build -o /ffuf

FROM alpine:3.19
COPY --from=build /ffuf /usr/bin/ffuf
ENTRYPOINT ["/usr/bin/ffuf"]