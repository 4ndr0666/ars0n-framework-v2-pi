FROM golang:1.21 AS build
WORKDIR /src
RUN git clone --depth 1 https://github.com/j3ssie/metabigor.git .
RUN CGO_ENABLED=0 go build -o /metabigor .

FROM alpine:3.19
COPY --from=build /metabigor /usr/bin/metabigor
ENTRYPOINT ["/usr/bin/metabigor"]