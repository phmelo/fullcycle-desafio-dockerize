FROM golang:1.13

WORKDIR /go/src/app
COPY ./hello-world.go .

RUN go build ./hello-world.go
RUN ./hello-world

ENTRYPOINT ["./hello-world"]
