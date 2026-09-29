# Deploying the density API

Runbook for Phase 9.2 ("Deploy to Ubuntu VPS"): the one-time VPS setup, the
first deploy, and what to do on later deploys. It started with issue #47
(TLS, key storage, backups, rate limiting, process supervision) and was
reworked to match how `neonpixel-website` already deploys to the same VPS:
a framework-dependent publish, uploaded by GitHub Actions
(`.github/workflows/deploy-api.yml`) into `releases/<id>/`, a `current`
symlink, a systemd service on localhost, and nginx + certbot in front.
Postgres comes from Ubuntu's own package. Nothing on the VPS uses containers,
and the VPS never has the .NET SDK or a checkout of this repo: migrations and
the seed run from a Mac through an SSH tunnel (§8).

The container setup in `api/Dockerfile` and `api/compose.yml` is for local
development only.

This repo is public, so the real host, paths and port never go in a committed
file. They appear below as placeholders, and the ones the workflow needs are
GitHub Actions secrets:

- `<vps-host>`: the VPS's hostname or IP (secret `VPS_HOST`)
- `<ssh-port>`: its SSH port (secret `VPS_SSH_PORT`)
- `<admin-user>`: your own SSH account on the VPS, with sudo
- `<deploy-user>`: the account GitHub Actions deploys as (secret `VPS_USER`)
- `<deploy-path>`: where releases live (secret `VPS_DEPLOY_PATH`)
- `<service-name>`: the systemd unit's name without `.service` (secret `VPS_SERVICE_NAME`)
- `<env-file>`: the file holding the production keys and connection string
- `<port>`: the localhost port the API listens on. Pick one nothing else uses;
  the website already uses 5000.
- `<api-hostname>`: the public hostname (secret `API_HOSTNAME`)
- `<backup-dir>`: where nightly database dumps go

## 1. Deploy user

A separate user from the website's, so each app's deploy key can only touch
its own releases.

```sh
sudo adduser --disabled-password --gecos "" <deploy-user>
echo "<deploy-user> ALL=(ALL) NOPASSWD: /bin/systemctl restart <service-name>.service" \
  | sudo tee /etc/sudoers.d/<deploy-user>-restart
sudo chmod 440 /etc/sudoers.d/<deploy-user>-restart
```

sudo matches the command literally, which is why the workflow restarts
`<service-name>.service` with the suffix.

## 2. Deploy key and GitHub secrets

On the Mac:

```sh
ssh-keygen -t ed25519 -f ./density_api_deploy_key -N "" -C "pocket-chef-density-api-deploy"
ssh-copy-id -p <ssh-port> -i ./density_api_deploy_key.pub <deploy-user>@<vps-host>
ssh-keyscan -p <ssh-port> <vps-host>
```

In the pocket-chef repo's Settings → Secrets and variables → Actions, add:

- `VPS_DEPLOY_KEY`: the contents of `density_api_deploy_key` (the private key).
  Delete the local file afterwards; it only needs to live in the secret.
- `VPS_KNOWN_HOSTS`: the full `ssh-keyscan` output. The workflow checks the
  host key against it, so a spoofed server is refused. ssh looks the key up
  by the exact value of `VPS_HOST`, so scan that same hostname or IP: scanning
  the IP while `VPS_HOST` holds the DNS name (or the reverse) fails the first
  deploy with a host-key error.
- `VPS_HOST`, `VPS_SSH_PORT`, `VPS_USER`, `VPS_DEPLOY_PATH`,
  `VPS_SERVICE_NAME`, `API_HOSTNAME`: see the placeholder list above.
- `API_READ_KEY`: the production read key from §4. The smoke test reads
  `/density-entries` with it, the one check that proves the deployed code
  works against the production schema. The key ships in the app anyway
  (Phase 10), so it's no more exposed here.

The write key and database password are not GitHub secrets. They live only
in `<env-file>` on the VPS (§4).

## 3. Runtime and Postgres

The workflow uploads releases with `rsync`, which has to be on the VPS as
well as the runner. Most Ubuntu server installs include it; `which rsync`
confirms, and `sudo apt-get install -y rsync` adds it if not.

The ASP.NET Core runtime is already there if the website is on this VPS
(`dotnet --list-runtimes` shows `Microsoft.AspNetCore.App 10.0.x`). If not,
install `aspnetcore-runtime-10.0` the way the website's `DEPLOYMENT.md` does.

Postgres:

```sh
sudo apt-get install -y postgresql
sudo -u postgres createuser --pwprompt densityapi
sudo -u postgres createdb --owner densityapi densityapi
```

Use a generated password without shell or quoting characters, e.g.
`openssl rand -hex 32`. The `densityapi` role owns the database, which is
enough for the first migration to create the `citext` extension (a trusted
extension, so no superuser is needed).

Ubuntu's Postgres listens on localhost only, and its default `pg_hba.conf`
accepts password logins from localhost, so nothing else needs configuring.
Leave it that way: the SSH tunnel in §8 is how the Mac reaches it.

Updates come with `apt upgrade`. A new Ubuntu release may bring a new
Postgres major version; `pg_upgradecluster` moves the data across.

## 4. Directories and the env file

```sh
sudo mkdir -p <deploy-path>/releases
sudo chown -R <deploy-user>:<deploy-user> <deploy-path>
```

The ownership matters: the workflow creates releases and switches the symlink
as `<deploy-user>` without sudo, and fails with `Permission denied` if
`<deploy-path>` belongs to root.

`<env-file>` goes outside `<deploy-path>`, owned by root with mode 600.
systemd reads it as root before starting the service, so the service user
never needs to read it, and a deploy can't touch it:

```sh
sudo install -m 600 -o root -g root /dev/null <env-file>
sudoedit <env-file>
```

```
ConnectionStrings__DensityApi=Host=localhost;Port=5432;Database=densityapi;Username=densityapi;Password=<db password>
ApiKeys__ReadApiKey=<read key>
ApiKeys__WriteApiKey=<write key>
```

Generate both keys with `openssl rand -hex 32`. The read key will ship inside
the app (Phase 10), so treat it as public. Keep the write key private: it's
the only way to change density data.

`Program.cs` refuses to start without the connection string and both keys.
The committed `appsettings.json` has none of them and never should.

## 5. systemd unit

`/etc/systemd/system/<service-name>.service`:

```ini
[Unit]
Description=Pocket Chef density API
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=<deploy-user>
WorkingDirectory=<deploy-path>/current
ExecStart=/usr/bin/dotnet <deploy-path>/current/PocketChef.DensityApi.Api.dll
Restart=on-failure
RestartSec=5
KillSignal=SIGINT
SyslogIdentifier=<service-name>
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://127.0.0.1:<port>
EnvironmentFile=<env-file>

[Install]
WantedBy=multi-user.target
```

```sh
sudo systemctl daemon-reload
sudo systemctl enable <service-name>.service
```

Don't start it yet: `<deploy-path>/current` only exists after the first
deploy. Logs: `journalctl -u <service-name>`.

## 6. nginx and HTTPS

Point `<api-hostname>`'s DNS at the VPS first.
`/etc/nginx/sites-available/<api-hostname>`:

```nginx
server {
    listen 80;
    server_name <api-hostname>;

    location / {
        proxy_pass http://127.0.0.1:<port>;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

`X-Forwarded-For` is set to `$remote_addr`, replacing anything the client
sent. The rate limiter (§10) counts requests per address using the first
value of that header. nginx's usual `$proxy_add_x_forwarded_for` appends to
the client's header instead, so a client could send a different fake address
on every request and never be limited.

```sh
sudo ln -s /etc/nginx/sites-available/<api-hostname> /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d <api-hostname>
sudo certbot renew --dry-run
```

certbot adds the HTTPS server block and the redirect from port 80, and
renews the certificate automatically.

## 7. Deploying

In GitHub: Actions → **Deploy density API** → Run workflow, on `main`. It
builds and tests `api/`, publishes it, uploads it to a new
`<deploy-path>/releases/<UTC timestamp>/`, points `current` at it, restarts
the service, keeps the 5 newest releases, and then checks that
`https://<api-hostname>/health` returns 200, that a write without a key
gets 401, and that a read with the read key gets 200. Run on any other branch, it builds and tests but doesn't deploy.

**If the change adds a migration, apply it (§8) before running the
workflow.** The new code expects the new schema. Migrations are never run
automatically, so a bad one can't apply itself to production unreviewed.

Rollback: SSH in as `<admin-user>`, point `current` at an older release and
restart:

```sh
cd <deploy-path>
ls releases
sudo -u <deploy-user> ln -sfn releases/<older-id> current
sudo systemctl restart <service-name>.service
```

If the newer release came with a migration, the older code may not work
with the migrated schema, so check before rolling back.

## 8. Migrations and seeding from the Mac

Open a tunnel to the VPS's Postgres in one terminal and leave it running:

```sh
ssh -N -L 15432:localhost:5432 -p <ssh-port> <admin-user>@<vps-host>
```

In another, from `api/`, with the production connection string pointed at
the tunnel:

```sh
export PROD_DB="Host=localhost;Port=15432;Database=densityapi;Username=densityapi;Password=<db password>"

dotnet ef database update \
  --project src/PocketChef.DensityApi.Infrastructure \
  --startup-project src/PocketChef.DensityApi.Api \
  --connection "$PROD_DB"
```

**Seed the table once**, after the first migration (PLAN.md Phase 9.1). The
seed tool only inserts ingredients that aren't in the table yet, so
re-running it after hand curation changes nothing. `--dry-run` shows what it
would insert without writing:

```sh
dotnet run --project src/PocketChef.DensityApi.Seed -- --connection "$PROD_DB" --dry-run
dotnet run --project src/PocketChef.DensityApi.Seed -- --connection "$PROD_DB"
```

The seed tool refuses to run while migrations are pending.

**Names in the table must stay canonical** (NFC + trimmed, enforced by the
`DensityEntry` constructor, issue #55). The upsert lookup is byte-exact
except for case, so a non-canonical row (from a hand edit in SQL, say) is
never found by a later upsert: re-POSTing that ingredient inserts a
duplicate instead of updating it. If you spot one, fix it in place or delete
it. The seed tool builds its rows through the constructor, so it can't
produce one.

## 9. Backups

The density table is small, hand-curated reference data with writes only
when someone curates it, so a nightly dump is enough. If it's ever lost, the
seed data (§8) rebuilds most of it.

```sh
sudo install -d -m 700 -o postgres -g postgres <backup-dir>
```

`/etc/cron.d/<service-name>-backup`:

```
30 3 * * * postgres pg_dump -Fc densityapi > <backup-dir>/densityapi-$(date +\%F).dump && find <backup-dir> -name '*.dump' -mtime +14 -delete
```

This runs as the `postgres` user, which logs in through the local socket
without a password, and keeps 14 days of dumps. `%` has to be escaped in
cron files. If the VPS already copies backups off the machine for the
website, add `<backup-dir>` to it.

Restore into the (existing, empty) database:

```sh
sudo -u postgres pg_restore --clean --if-exists -d densityapi <backup-dir>/densityapi-<date>.dump
```

## 10. Rate limiting

Nothing to configure on the VPS: it's in the app. `GET /density-entries`
allows 60 requests per minute per client address and returns 429 with a
`Retry-After` header past that (`RateLimiting/`, covered by
`DensityEntriesRateLimitTests`). It exists because the read key ships inside
the app and can be extracted. The limit applies to every caller of the read
endpoint, with or without a key, since it runs before the key check. The
write endpoint isn't limited: only the write key's holder can use it.

The limit is configurable (`RateLimiting:Read:PermitLimit` and
`WindowSeconds`, 60/60 by default) so tests can use a small number.

## 11. Troubleshooting

What went wrong on the first setup, by the workflow step or symptom it
showed up as. After a fix on the VPS, use **Re-run failed jobs** on the
workflow run: it reuses the build output that already passed.

**Tunnel (§8): `Permission denied (publickey)`.** ssh only offered its
default keys. If your admin key has another name, pass it with `-i`, or use
the `Host` alias from your `~/.ssh/config`:
`ssh -N -L 15432:localhost:5432 <alias>`.

**Upload release: `mkdir: Permission denied`.** `<deploy-path>` isn't owned
by the deploy user, or the `VPS_DEPLOY_PATH` secret points somewhere else.
Check with `ls -ld <deploy-path> <deploy-path>/releases` and
`sudo -u <deploy-user> mkdir -p <deploy-path>/releases/test`, then rerun the
`chown` in §4.

**Restart service: `sudo: A terminal is required to authenticate`.** No
sudoers rule matched, so sudo asked for a password. `sudo -l -U <deploy-user>`
must list `/bin/systemctl restart <service-name>.service`. If it doesn't, check
that the file in `/etc/sudoers.d/` is mode 440, has no `.` in its name (sudo
skips those), and passes `sudo visudo -c`. If it does, compare it with the
secrets: `VPS_SERVICE_NAME` is the name without `.service`, which the
workflow adds. `sudo -u <deploy-user> sudo -n systemctl restart
<service-name>.service` runs the exact command without prompting.

**Smoke test: `/health` returns 404.** Something other than the API
answered. If nginx's error log says `directory index of
"<deploy-path>/current/" is forbidden`, the site has a `root`/`try_files`
block from a template instead of the `proxy_pass` in §6: nginx is serving
the release folder as static files. Replace it with §6's `location /` in
every `server` block for the hostname (certbot's 443 block is in the same
file), and check that no other file in `sites-enabled` claims the hostname.
If the response is the website's, `proxy_pass` points at its port.

**Smoke test: `/health` returns 502.** nginx is forwarding, but the API isn't
listening on that port. `systemctl status <service-name>` and
`journalctl -u <service-name> -n 50` say why. `Failed to determine
credentials for user '': Unknown user` means `User=` is empty in the unit,
which happens when the unit is written through a heredoc with a shell
variable that wasn't set; check `systemctl cat <service-name>` for any other
empty value, fix it, then `daemon-reload` and restart. If the service is
running, compare `ss -ltnp | grep dotnet` with the `proxy_pass` port.

## Checklist

- [ ] Deploy user created, sudo only for restarting the service (§1)
- [ ] Deploy key installed, all 9 GitHub secrets set (§2)
- [ ] rsync and the ASP.NET Core 10 runtime installed; Postgres installed with the
      `densityapi` role and database (§3)
- [ ] `<deploy-path>/releases` owned by the deploy user; `<env-file>` written,
      root-owned, mode 600 (§4)
- [ ] systemd unit installed and enabled, not started (§5)
- [ ] DNS points at the VPS; nginx site enabled; certbot certificate issued (§6)
- [ ] Migrations applied and the table seeded from the Mac (§8)
- [ ] Deploy workflow run on `main`, smoke test passed (§7)
- [ ] From outside the VPS: `GET https://<api-hostname>/density-entries` with
      the read key returns the seeded entries (PLAN.md 9.2 acceptance)
- [ ] Backup cron installed and the first dump written (§9)
