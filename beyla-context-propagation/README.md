# Beyla: Context propagation demo

Demonstration of propagation of trace context between services with Beyla (OBI) on Kubernetes.

## Getting started

Run the following command to start the services:

```shell
docker compose up
```

Or if you're using podman - don't forget to run as root:

```shell
sudo podman-compose up
```

Access the blog:

```shell
curl localhost:18443

curl https://localhost:18443/entry/about.md
```

This fetches the blog homepage and then fetches a post.

