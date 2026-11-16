# Deployment Assignment Report

Application: Taskify Guestbook
Domain: taskify.click
GitHub repository: DevHammad0/taskify-deployment-assignment
AWS region: eu-north-1

I built a small guestbook with Laravel. Visitors can add entries and see them on the page. The health page returns OK when the app can connect to MySQL.

## Task 1 — Deploy the app

I first ran Laravel and MySQL together on app-vm. I added an entry to check that the app could save and show data. I set the app to production mode, protected its environment file, and configured Nginx for my domain. I also enabled HTTPS and redirected HTTP to HTTPS.

The health page returned OK, the bare IP did not show the site, and the environment file could not be downloaded. Evidence: evidence/task1-app-vm.txt.

## Task 2 — Move the database

I put the app into maintenance mode while copying the database from app-vm to db-vm. My original guestbook entry was still there after the move. I pointed Laravel to the database’s private address, then stopped and disabled MySQL on app-vm.

Only app-vm can connect to MySQL, and the app’s database account can log in only from that server. Evidence: evidence/task2-db-vm.txt and evidence/task2-network-rules.txt.

## Task 3 — Deploy updates

I put the code in a private GitHub repository. A push to main starts the workflow. It runs tests first, deploys only when they pass, applies migrations, and checks the live site. I can also start the workflow manually. A concurrency setting prevents overlapping deployments.

I made a visible page update, then added an optional location field with a database migration. Both deployed through the workflow. I also introduced a spelling mistake in the allowed topic value. The tests failed and deployment was skipped. I fixed the value in Git, and the workflow passed again.

Evidence: evidence/task3-workflows.txt. The successful runs were 43778418653 for the page update, 43778544322 for the migration, and 43778725045 for the fix. Run 43778647326 shows the test failure and skipped deployment.

## Task 4 — Back up the database

I set up hourly backups on app-vm. The job uses a separate read-only database account, compresses and checks each backup, logs failures, and deletes backups after seven days. Only the backup account can read the backup folder. The 00:15 backup on November 16 included the new location column.

For the restore drill, I stopped db-vm and restored a backup on app-vm. The site was back in about 62 seconds. The backup did not include the entry added after it was made. After restarting db-vm, I restored that entry and the entry created during the outage.

Evidence: evidence/task4-backups.txt and evidence/task4-disaster-drill.txt.

## Task 5 — Clean up Laravel logs

Laravel writes daily log files. A nightly job compresses logs older than one day, deletes compressed logs after 14 days, and writes a warning if the log folder exceeds 500 MB. It leaves .gitignore and other unrelated files alone. I tested the cleanup with sample files and confirmed a second run made no further changes. Ubuntu rotates Nginx and MySQL logs with its existing logrotate rules.

Evidence: evidence/task5-log-cleanup.txt.

## Questions

1. Why can the app’s database user connect only from app-vm? The app is the only server that needs the account. Limiting its source reduces where stolen credentials could be used.
2. Did the broken update affect the live site? No. Tests failed, so deployment did not run and the working version stayed online. Requiring review and passing checks before merging to main would provide another safeguard.
3. Why keep backups on app-vm? A backup there is still available if db-vm fails. If app-vm also fails, those backups are lost, so a second copy should be kept elsewhere.
4. How much data could be lost with hourly backups? About one hour of changes, plus the time needed to make the next successful backup.
5. Why test restores, and how often? A backup is useful only if it can be restored. I would test a restore monthly and after major database or backup changes.
6. How does the browser find the server and choose the site? DNS gives the browser the app server’s IP address. The browser sends the domain name with its request, and Nginx uses that name to choose the site.

## Problems I fixed

I matched Composer’s PHP version to the server and fixed the test database setup. I adjusted the backup command to work with the limited backup account and detect incomplete backups. During the DNS change, some resolvers kept the old address. I removed an old local hosts-file entry. Google DNS, Cloudflare DNS, and my workstation now reach the app, and both domain health checks return OK.
