# Taskify Guestbook deployment assignment

A small Laravel 12 guestbook used to demonstrate a two-VM production deployment. Visitors can add and read entries stored in MySQL. `/health` returns `OK` only when Laravel can reach MySQL.

## Production layout

- `app-vm`: Nginx, PHP-FPM, Laravel, the scheduled database backups, and the recovery MySQL server.
- `db-vm`: the primary MySQL server. Its security group permits MySQL only from the app VM security group.
- Domain: `taskify.click`.
- Deployments: private GitHub repository; a test job must pass before the self-hosted app VM runner deploys a release.

No production `.env`, database password, SSH private key, or GitHub credential belongs in this repository. Production environment files and backup credentials are provisioned on the servers with restrictive permissions.

## Scripts

- `scripts/backup-mysql.sh`: compressed, verified, timestamped dump with failure cleanup and retention.
- `scripts/cleanup-laravel-logs.sh`: compresses only old Laravel daily logs, expires old archives, and warns at the configured size limit.
- `scripts/deploy-release.sh`: installs dependencies and migrations, rebuilds caches, atomically switches releases, and rolls back on a local health failure.

The domain A records point to `app-vm`. HTTPS is enabled for both names, and Certbot renews the certificate using its system timer.

See [`report.md`](report.md) for the implementation notes and evidence for each assignment task.
