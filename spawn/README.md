* QingCloud ap1
* 2 Core, 2 GB
* Ubuntu Server 14.04.2 LTS 64bit

## Install Docker

    curl -sSL https://get.docker.com/ | sh
    curl -L https://github.com/docker/compose/releases/download/1.4.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    useradd -m -g docker docker

## Nginx

    apt-get install nginx

* /etc/nginx/keys
* /home/docker/sites

    * blog
    * cats-blog
    * jybox.net
    * mabolo
    * old-bbs
    * random
    * rootpanel
    * rpvhost-blog

## Home

* atom-china

    [discourse/launcher](https://github.com/discourse/discourse_docker)

* servers

    [jysperm/servers](https://github.com/jysperm/servers)
