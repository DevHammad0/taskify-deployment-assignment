# GitHub Actions evidence

Repository: https://github.com/DevHammad0/taskify-deployment-assignment (private)

- Visible headline update: [workflow run 43770112276](https://github.com/DevHammad0/taskify-deployment-assignment/actions/runs/43770112276). Tests passed and the release deployed; the public health check returned 404 because DNS still resolved to the old VM.
- Migration update (`guestbook_entries.topic`): [workflow run 43770211586](https://github.com/DevHammad0/taskify-deployment-assignment/actions/runs/43770211586). Tests passed; the log shows the migration completed and `Deployed 1a6dab7... successfully`. Only the public health check failed on the stale DNS record.
- Deliberately broken topic validation: [workflow run 43770314399](https://github.com/DevHammad0/taskify-deployment-assignment/actions/runs/43770314399). Tests failed and the deploy job was skipped. The live app still displayed the working topic selector.
- Git fix: [workflow run 43770400055](https://github.com/DevHammad0/taskify-deployment-assignment/actions/runs/43770400055). Tests passed and the release deployed; its health step ran before the DNS and TLS cutover.
- Full HTTPS verification after DNS and TLS setup: [workflow run 43771858657](https://github.com/DevHammad0/taskify-deployment-assignment/actions/runs/43771858657). Test, deploy, and GitHub-hosted public verify jobs all succeeded.
- Subsequent full run after the final report/evidence update: [workflow run 43772047352](https://github.com/DevHammad0/taskify-deployment-assignment/actions/runs/43772047352). Test, deploy, and GitHub-hosted public verify jobs all succeeded.
- Post-cutover run after stopping the previous VM: [workflow run 43773123710](https://github.com/DevHammad0/taskify-deployment-assignment/actions/runs/43773123710). Test, deploy, and GitHub-hosted public verify jobs all succeeded.

The workflow has `push` to `main`, `workflow_dispatch`, a shared production concurrency group with cancellation disabled, and the deploy job depends on the test job.

The self-hosted runner's systemd service on `app-vm` is enabled and active, so workflow deployments do not require a person to log in to deploy.
