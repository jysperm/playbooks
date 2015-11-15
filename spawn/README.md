* QingCloud ap1
* 2 Core, 2 GB
* Ubuntu Server 14.04.2 LTS 64bit

## Install Docker

    curl -sSL https://get.docker.com/ | sh
    curl -L https://github.com/docker/compose/releases/download/1.4.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    useradd -m -g docker docker

## Home

* atom-china

    [discourse/launcher](https://github.com/discourse/discourse_docker)

* keys

    Nginx SSL Keys, `chmod 600 keys/*`

* servers

    [jysperm/servers](https://github.com/jysperm/servers)

* sites

    Nginx Sites

    * blog
    * cats-blog
    * jybox.net
    * mabolo
    * old-bbs
    * random
    * rootpanel
    * rpvhost-blog
