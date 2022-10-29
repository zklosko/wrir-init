# wrir-init

Contains application code for our archive API, Icecast server, and stream recorder. Please keep `user.passwd` file private; it's used for our WebDAV service and contains hashed passwords.

## Instructions

1. Install Ubuntu Server 20.04 LTS
2. Download repo with `git clone https://github.com/zklosko/wrir-init.git`
3. Run init file -> `sudo bash init.sh`
4. Profit

docker run -p 5432:5432 -e POSTGRES_DB=wrirtest -e POSTGRES_USER=app -e POSTGRES_PASSWORD=password -v /home/zack/database:/var/lib/postgresql/data --restart=always -d postgres:latest