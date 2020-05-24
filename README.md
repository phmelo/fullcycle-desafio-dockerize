# Full Cycle - Desafio 02

**1)** Utilize o sistema de templates do Dockerize para deixar o arquivo **nginx.conf** mais flexível, ou seja, tanto o **host** e **porta** da chamada possam ser definidos como variáveis de ambiente no docker-compose.yaml. 



Solução:

- Criar um arquivo de template do NGINX

```nginx
./.docker/nginx/nginx.conf.tmpl
server {
    listen 80;
    index index.php index.html;
    root /var/www/public;

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass {{.Env.APP_HOST}}:{{.Env.APP_PORT}};
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    location / {
        try_files $uri $uri/ /index.php?$query_string;
        gzip_static on;
    }
}

```



- Adicionar ao Dockerfile do NGINX a instalação do Dockerize
- Copiar o arquivo de template para o Container do NGINX
- Remover o arquivo de configuração padrão do NGINX

```dockerfile
./.docker/nginx/Dockerfile
FROM nginx:1.15.0-alpine

RUN apk add --no-cache openssl

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz
    
RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf.tmpl /etc/nginx/conf.d/

```



- Alterar o arquivo docker-compose para utilizar o dockerize para criar o novo arquivo nginx.conf a partir do template nginx.conf.tmpl
  - Atenção no "entrypoint" e no "command", sem o command o nginx não iniciou.

```yaml
./docker-compose.yaml
...
nginx:
    build: .docker/nginx
    container_name: nginx
    entrypoint: dockerize -template /etc/nginx/conf.d/nginx.conf.tmpl:/etc/nginx/conf.d/nginx.conf nginx
    command: -g "daemon off;" -c /etc/nginx/nginx.conf
    environment:
        - APP_HOST=app
        - APP_PORT=9000
    restart: always
...

```





**2)** Você terá que publicar uma imagem no docker hub. Quando executarmos:
docker run <seu-user>/codeeducation 
Temos que ter o seguinte resultado: Code.education Rocks!

**3)** A imagem de nosso projeto Go precisa ter menos de 2MB =)

Solução:

- Instalar o Golang

```
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install golang-go -y
```

- Criar um hello-world.go

```go
package main
import "fmt"
func main() {
  fmt.Printf("Code.education Rocks!\n")
}
```

- Criar uma imagem docker com o código 

```dockerfile
FROM golang:1.13

WORKDIR /go/src/app
COPY ./hello-world.go .

RUN go build ./hello-world.go
RUN ./hello-world

ENTRYPOINT ["./hello-world"]
```



- Criar uma nova imagem menor, usando multistaging build

```dockerfile
FROM golang:alpine as builder

WORKDIR /app
COPY hello-world.go .
RUN GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /app/hello-world .

FROM scratch
COPY --from=builder /app/hello-world .

ENTRYPOINT ["/hello-world"]
```



A única forma dessa imagem ficar com menos de 2MB foi utilizando o comando:

```dockerfile
RUN GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /app/hello-world .
```

A tentativa com o "alpine:3.11" ficou com ~7MB e com o SCRATCH sem o comando acima ficou com ~2MB.



Para baixar e rodar o container no Docker Hub: 

```
docker run phmelomorais/codeeducation
```



