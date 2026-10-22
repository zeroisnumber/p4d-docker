# p4d-docker

A small Docker image for the Perforce Helix Core server (`p4d`), built from Perforce's official apt repository.

- `p4d` runs in the foreground as the container's main process, so `restart: unless-stopped` brings it back after a host reboot and `docker stop` shuts it down cleanly.
- All server data lives on one mounted volume.
- Rebuilding the image picks up the latest `p4d` release.

Tested on a Synology DS220+ (Container Manager) with p4d 2026.1.

## Quick start

```bash
git clone https://github.com/zeroisnumber/p4d-docker.git
cd p4d-docker
mkdir -p data          # Synology Docker does not create missing bind-mount folders
docker compose up -d --build
```

Then, from a machine with the `p4` client:

```bash
p4 -p <host>:1666 -u super user -f super    # create the admin user
p4 -p <host>:1666 -u super protect          # save the default table: makes 'super' the only super user
p4 -p <host>:1666 -u super passwd
p4 -p <host>:1666 -u super serverid master
p4 -p <host>:1666 -u super configure set security=3
```

On Synology you can instead add the folder as a **Project** in Container Manager and build it there.

## Configuration

| Variable | Default | Meaning |
|---|---|---|
| `P4ROOT` | `/p4/root` | Server root (`db.*` files). Depots are created under it unless `server.depot.root` is set. |
| `P4PORT` | `1666` | Listen address, e.g. `ssl:1666` (then also set `P4SSLDIR`). |
| `P4D_CASE` | unset | `1` = case-insensitive, `0` = case-sensitive. Only applied when the database is first created. |

Extra arguments after the image name are passed straight to `p4d`.

The container runs as root. If you prefer a dedicated user, add `USER` to the Dockerfile and make sure the mounted files are owned by that uid.

## Backups

`scripts/checkpoint.sh` takes a compressed checkpoint of the running server and deletes checkpoints and rotated journals older than `KEEP_DAYS` (30 by default).

```bash
CONTAINER=p4d DOCKER=/usr/local/bin/docker bash scripts/checkpoint.sh
```

Schedule it daily (cron, or the Synology Task Scheduler as root), and back up the whole `data/` folder. To restore you need the latest checkpoint, the journal written since then, and the depot archive files.

## Upgrading p4d

```bash
docker compose exec p4d sh -c 'p4d -r "$P4ROOT" -jc'   # checkpoint first; -xu cannot be undone
docker compose build --pull
docker compose stop p4d
docker compose run --rm p4d -xu            # upgrade the database schema
docker compose up -d
```

## Moving an existing server into this image

1. Find how the old server is laid out: `p4d -r <root> -cshow` lists configurables such as `P4JOURNAL`, `P4LOG` and `server.depot.root`. These are often stored as paths relative to `P4ROOT` (`../archives`, `../journals/journal`).
2. Mount the old server directory at **the same path inside the container** and set `P4ROOT` to match, so those relative paths keep working. For example, for a server created by `configure-helix-p4d.sh`:

   ```yaml
   environment:
     P4ROOT: /opt/perforce/servers/master/root
   volumes:
     - /path/to/master:/opt/perforce/servers/master
   ```

3. Stop the old server, take a checkpoint (`p4d -r <root> -jc`), and copy the directory **with ownership preserved** (for example `tar` piped into a root container, not a plain `docker cp`). Compare file counts and sizes before going further.
4. Run `-xu` once with the new image, start it, and run `p4 verify -q //...` to check every revision.

Leave `P4D_CASE` unset for an existing server; the case handling is already stored in its database.

## License

MIT
