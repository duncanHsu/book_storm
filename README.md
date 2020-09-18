# Book_Storm

Create a http server using koa,and deploy a Docker container.

## Mirgrate Command

  ```
    npm run mirgrate
  ```

### Docker Instructions

---

Start services using docker, you need to create an images before starting the container.

### Build Image

  ```
    docker build . -t book_storm:tag
  ```
### Start Container

  ```
    docker-compose up -d --build
  ```

## Environment variables

---

 * PORT : By default a Http server listens on port 3000,that you can change it through the docker `run` command.

 * DB_HOST : The host address for the database. The default is mymongo, that you can change it through the docker `run` command.

 * DB_PORT : The pory for the database. The default is 27017, that you can change it through the docker `run` command.

 * DB_USERNAME: The name of the database user to user. The docker setup uses the default user so this is not usually required.

 * DB_PASSWARD: The password for the database. The docker setup does not require this.

 * DB_NAME: This parameter must be specified and must correspond to the name specified in the CREATE DATABASE statement.
 
## Unit Test

---

  Local replica set using run-rs to atomic transaction

  ```
    npm test
  ```


