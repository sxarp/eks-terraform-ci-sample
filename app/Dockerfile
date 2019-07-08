# multi-stage buildしています
# image sizeは6Mくらい
# 参考: https://medium.com/@chemidy/create-the-smallest-and-secured-golang-docker-image-based-on-scratch-4752223b7324

FROM golang:1.12.6 AS builder

ENV GO111MODULE=on

WORKDIR /app

COPY . .

# CGO_ENABLED=0を指定しないと、以下のようなエラーが出る:
# `standard_init_linux.go:207: exec user process caused "no such file or directory"`
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s"

FROM scratch

COPY --from=builder /app/app /app

ENTRYPOINT ["/app"]
