To use it:

``` bash
docker volume create one-docker
docker volume create one-home
docker run --privileged -d --init -p 2222:22 -v one-home:/home/one -v one-docker:/var/lib/docker gllera/ws

# user: one
# pass: one
ssh -p 2222 one@localhost

(notice that you will have another docker daemon running independently inside this container)
```
