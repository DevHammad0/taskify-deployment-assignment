# Deployment Assignment Report

**Application:** Taskify Guestbook  
**Domain:** [taskify.click](https://taskify.click)
**GitHub repository:** [DevHammad0/taskify-deployment-assignment](https://github.com/DevHammad0/taskify-deployment-assignment)
**AWS region:** `eu-north-1`

I built a small Laravel guestbook. Visitors can add an entry and see the saved entries on the page. The `/health` page returns `OK` when the app can connect to MySQL.

## Task 1 — Deploy the app

I first ran Laravel and MySQL together on `app-vm`. I added a guestbook entry to check that the app could save and display data. I set the app to production mode, protected its `.env` file, and configured Nginx to serve the site for my domain. I also enabled HTTPS and redirected HTTP to HTTPS.

**Proof:** The health check returned `OK`; the bare IP did not show the site; and the browser could not download `.env`. See [Task 1 evidence](evidence/task1-app-vm.txt).

## Task 2 — Move the database

I put the app into maintenance mode while I copied its database from `app-vm` to `db-vm`. The original guestbook entry was still there after the move. I then pointed Laravel to the database’s private address and stopped and disabled MySQL on `app-vm`.

Only `app-vm` can connect to MySQL, and the app’s database account can log in only from that server.

**Proof:** The app returned `OK` while using `db-vm`, and the original entry remained in the database. See [database evidence](evidence/task2-db-vm.txt) and [network rules](evidence/task2-network-rules.txt).

## Task 3 — Deploy updates with GitHub Actions

I made the GitHub repository private. When I push to `main`, GitHub Actions runs the tests; if they pass, it deploys the update. I can also start the workflow manually. The workflow applies migrations, prepares Laravel’s caches, and checks the site. It prevents overlapping deployments.

I changed the page, then added a database column and showed it on the page. Both updates were deployed through GitHub Actions. I also pushed an intentional spelling mistake: the tests failed, so the deploy did not run. I fixed the mistake in Git, and the workflow passed again.

**Proof:** [Update 1](https://github.com/DevHammad0/taskify-deployment-assignment/actions/runs/43770112276), [database update](https://github.com/DevHammad0/taskify-deployment-assignment/actions/runs/43770211586), [broken update](https://github.com/DevHammad0/taskify-deployment-assignment/actions/runs/43770314399), [fix](https://github.com/DevHammad0/taskify-deployment-assignment/actions/runs/43770400055), and [latest successful deployment and public check](https://github.com/DevHammad0/taskify-deployment-assignment/actions/runs/43774870084). More details are in [workflow evidence](evidence/task3-workflows.md).

## Task 4 — Back up the database

I set up an hourly backup job on `app-vm`. It uses a separate read-only database account, compresses and checks each backup, records failures, and deletes backups after seven days. Only the backup account can read the backup folder.

For the restore drill, I stopped `db-vm` and restored the latest backup on `app-vm`. The site was back in about 62 seconds. The backup did not contain the entry added after it was made, so after restarting `db-vm` I restored that entry and the entry created during the outage.

**Proof:** See the [backup evidence](evidence/task4-backups.txt) and [restore drill notes](evidence/task4-disaster-drill.txt).

## Task 5 — Clean up Laravel logs

I configured Laravel to create daily log files. A nightly job compresses logs older than one day, deletes compressed logs older than 14 days, and writes a warning if the folder exceeds 500 MB. It leaves `.gitignore` and unrelated files alone. I tested it with sample files and confirmed the second run made no further changes. Ubuntu already rotates Nginx and MySQL logs using its `logrotate` rules.

**Proof:** See [log cleanup evidence](evidence/task5-log-cleanup.txt).

## Questions

1. **Why can the app’s database user connect only from `app-vm`?** The app is the only server that needs the account, so limiting its source reduces the chance of someone using stolen credentials elsewhere.
2. **Did the broken update affect the live site? What would prevent one from reaching it?** No. The tests failed, so the deploy job did not run and the working version stayed online. I would protect `main` and require passing tests and a review before merging.
3. **Why keep backups on `app-vm`? What if it fails too?** A backup on `app-vm` is still available if `db-vm` fails. If `app-vm` also fails, those backups are lost, so a second copy should be kept elsewhere.
4. **How much data could be lost with hourly backups?** About one hour of changes, plus the time needed to make the next successful backup.
5. **Why test restores, and how often?** A backup is useful only if it can be restored. I would test a restore monthly and after major database or backup changes.
6. **How does the browser find the server and choose the site?** DNS gives the browser the app server’s IP address. The browser sends the domain name with its request, and Nginx uses that name to choose the site.

## Problems I fixed

- I matched Composer’s PHP version to the server and fixed the test database setup so the workflow tests would pass.
- I adjusted the backup command to work with the limited backup account and to detect incomplete backups.
- DNS updates took time to appear on every resolver. I removed an old local hosts-file entry; this workstation now reaches the app through the domain. At the last check, Google DNS and the authoritative nameservers had the new address, while Cloudflare’s `1.1.1.1` resolver still had the old apex address cached.

## Submission note

I still need the instructor’s GitHub username to add them as a collaborator to the private repository.
