To use it:

``` bash
docker run -d --init -p 2222:22 \
-v one-ssh:/etc/ssh -v one-home:/home/one -v /var/run/docker.sock:/var/run/docker.sock \
-e TZ=Europe/Madrid gllera/ws

# user: one
# pass: one
ssh -p 2222 one@localhost
```
