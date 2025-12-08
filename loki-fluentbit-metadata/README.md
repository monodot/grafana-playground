# Loki: Sending Structured Metadata via Fluent Bit

This Compose example shows how to use Fluent Bit's Loki plugin to parse incoming JSON logs, and attach two pieces of _Structured Metadata_ to each log line.

The log lines are from **flog**, and look like this:

> {"host":"2.12.28.87","user-identifier":"pagac5723","datetime":"23/Oct/2024:14:30:36 +0000","method":"PUT","request":"/incubate/leverage/roi/leading-edge","protocol":"HTTP/2.0","status":406,"bytes":18403,"referer":"https://www.dynamicmetrics.biz/magnetic","source":"flog","type":"apache_access"}

The Fluent Bit pipeline sets the `job`, `source`, `type` labels statically. It also extracts the `method` field and uses it as a Loki label. Finally, it adds the `host` and `request` fields as structured metadata fields in Loki.

Ultimately the logs become searchable like this:

```
{source="flog", method="PUT"} | request = `/strategize/drive`

{job="fluentbit", method="GET"} | host = `192.168.1.1`
```

To run this example:

```shell
cp .env.example .env

vi .env   # set your Loki config environment variables here

podman-compose up
```
