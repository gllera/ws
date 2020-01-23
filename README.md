To use it:

``` bash
docker run --privileged -d --init -p 2222:22 \
-v one-ssh:/etc/ssh -v one-home:/home/one -v one-docker:/var/lib/docker \
-e TZ=Europe/Madrid gllera/ws

# user: one
# pass: one
ssh -p 2222 one@localhost

(notice that you will get another docker daemon running independently inside this container)
```
