# railway-rabbitmq-delayed

RabbitMQ for [Railway](https://railway.com) with the [`rabbitmq_delayed_message_exchange`](https://github.com/rabbitmq/rabbitmq-delayed-message-exchange) plugin pre-installed and enabled.

## Versions

| Component | Version |
|---|---|
| RabbitMQ | `4.2-management` (4.2.x line) |
| `rabbitmq_delayed_message_exchange` | `4.2.0` |

Pinned to the 4.2.x line because plugin v4.2.0 only targets 4.2.x. The 4.3.x RabbitMQ line has no matching plugin release at the time of writing.

## Deploy on Railway

1. Fork this repo (or use it directly).
2. In Railway: **New Project → Deploy from GitHub repo** → pick this repo.
3. Add a **Volume** mounted at `/var/lib/rabbitmq` so queues/state persist across deploys.
4. Done. The image builds from the `Dockerfile`; the start command in `railway.json` handles per-deploy config.

### What the start command does

```
echo 127.0.0.1 rabbitmq >> /etc/hosts
echo 'management_agent.disable_metrics_collector = false' > /etc/rabbitmq/conf.d/20-management_agent.disable_metrics_collector.conf
echo 'management.tcp.ip = ::' > /etc/rabbitmq/conf.d/10-defaults.conf
exec docker-entrypoint.sh rabbitmq-server
```

- **`/etc/hosts` entry** pins the Erlang node name to `rabbit@rabbitmq`. Without this, the node name follows the random Railway container hostname, which changes on every deploy and orphans the Mnesia data on the volume.
- **`management_agent.disable_metrics_collector = false`** keeps the management UI's per-object metrics enabled (Railway containers are small enough that the default off-by-default tradeoff isn't worth it).
- **`management.tcp.ip = ::`** binds the management UI on IPv6 wildcard so it's reachable over Railway's IPv6-only private network.

## Accessing the management UI

Railway services don't expose private ports publicly. To reach the management UI (port `15672`), deploy [`brody192/railway-public-to-private-proxy`](https://github.com/brody192/railway-public-to-private-proxy) as a second service in the same project with:

```
PROXY_HOST=${{RabbitMQ.RAILWAY_PRIVATE_DOMAIN}}
PROXY_PORT=15672
```

(Replace `RabbitMQ` with whatever you named the service.) Give the proxy service a public domain; visit it, log in with the default `guest` / `guest` (change this).

For external AMQP access, deploy a second proxy instance with `PROXY_PORT=5672`.

## Connecting from other Railway services

Use the private domain reference, AMQP port 5672:

```
amqp://guest:guest@${{RabbitMQ.RAILWAY_PRIVATE_DOMAIN}}:5672
```

## Using the delayed exchange

Declare an exchange of type `x-delayed-message` with an `x-delayed-type` argument specifying the underlying routing behavior:

```
arguments: { "x-delayed-type": "direct" }
```

Publish messages with an `x-delay` header (milliseconds):

```
headers: { "x-delay": 60000 }   // delivered ~60s later
```

See the [plugin README](https://github.com/rabbitmq/rabbitmq-delayed-message-exchange) for full semantics.

## Troubleshooting

### Boot hangs at `Starting broker...` then times out

Almost always a Mnesia / node-name mismatch on the persisted volume — typically from deploys made before the `/etc/hosts` pin was in place, or from a downgrade.

**Targeted fix (preserves the volume itself):**

1. Temporarily replace `deploy.startCommand` in `railway.json` with `"sleep infinity"`, push, wait for the deploy to go Active.
2. `railway ssh` into the service.
3. `rm -rf /var/lib/rabbitmq/mnesia/*`
4. Revert `railway.json`, push, and the next deploy will boot cleanly.

### Version upgrades

In-place upgrades within 4.x are fine. Downgrades and major-version skips (e.g. 3.12 → 4.2) are not supported by RabbitMQ — wipe the volume or step through intermediate versions first.

## License

Image build files are MIT. RabbitMQ and the delayed-exchange plugin retain their respective upstream licenses (MPL 2.0).
