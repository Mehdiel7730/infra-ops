# Contributing to infra-ops

This repository owns the full deployment lifecycle — AWS infrastructure provisioning via Terraform, server configuration via Ansible, and CI/CD orchestration via GitHub Actions. Changes here directly affect live environments. Read this guide fully before opening a pull request.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Branch Strategy](#branch-strategy)
- [Working with Terraform](#working-with-terraform)
- [Working with Ansible](#working-with-ansible)
- [Working with GitHub Actions Workflows](#working-with-github-actions-workflows)
- [Environment Promotion](#environment-promotion)
- [Secrets and Sensitive Values](#secrets-and-sensitive-values)
- [Pull Request Standards](#pull-request-standards)
- [Commit Message Convention](#commit-message-convention)
- [What Requires a Review](#what-requires-a-review)
- [What You Must Never Do](#what-you-must-never-do)

---

## Prerequisites

Before making any changes, ensure the following are installed and configured locally:

- **Terraform** >= 1.7.x — for planning and validating infrastructure changes
- **Ansible** >= 2.15.x with the `amazon.aws` collection installed
- **AWS CLI** v2, configured with a profile that has read-only access to dev at minimum
- **Python** >= 3.11 (required by Ansible and its AWS modules)
- **boto3** and **botocore** installed in the Python environment Ansible uses
- **pre-commit** — hooks are configured for this repo; run `pre-commit install` after cloning

If you do not have AWS credentials for the environment you are targeting, request them from the infrastructure owner before proceeding. Do not borrow or reuse someone else's credentials.

---

## Branch Strategy

```
main          ← reflects prod. protected. never commit directly.
staging       ← reflects staging. merges into main via PR after validation.
dev           ← reflects dev. base branch for all feature/fix work.
```

All work starts from a short-lived branch cut from `dev`:

```
feat/add-redis-role
fix/nginx-upstream-timeout
chore/upgrade-terraform-aws-provider
infra/add-staging-rds
```

Use the prefix that matches intent — `feat`, `fix`, `chore`, `infra`, `ci`, `docs`. PRs from feature branches target `dev`. Promotion from `dev → staging → main` happens through reviewed PRs only.

---

## Working with Terraform

### Before you start

Run `bootstrap-state.sh` only once per environment, and only if the S3 backend and DynamoDB lock table do not yet exist. This script is intentionally idempotent but should not be run on already-initialized environments without understanding what it does.

### Local validation workflow

Always work inside the specific environment directory, never at the repo root:

```bash
cd terraform/environments/dev

terraform init          # initializes backend, downloads providers
terraform validate      # syntax and schema check
terraform fmt -check    # fails if formatting is off; run fmt to fix
terraform plan          # review what will change before any PR
```

Never run `terraform apply` locally against staging or prod. All applies to those environments go through the `terraform.yml` GitHub Actions workflow only.

For dev, a local apply is permitted when you are actively building and testing a module, but state must remain consistent — do not apply something locally and then let the pipeline diverge from it.

### Module changes

When modifying anything under `terraform/modules/`, check which environments consume that module before changing its interface. A variable rename or output removal in `modules/compute` will break all three environment `main.tf` files that call it. Update all callers in the same PR — do not leave environments in a broken state across separate PRs.

### Provider and backend versioning

Provider version constraints live in each environment's `main.tf`. Do not widen a constraint (e.g., `~> 5.0` to `>= 5.0`) without testing the upgrade. Pin to the minor version at minimum.

### Formatting

All `.tf` files must pass `terraform fmt`. The `terraform.yml` workflow enforces this and will fail the pipeline if formatting is off.

---

## Working with Ansible

### Inventory

Inventories are environment-specific and live under `ansible/inventories/`. Do not hardcode IP addresses in playbooks or roles — all host targeting goes through the inventory files. If an EC2 IP changes after Terraform reprovisioning, update the corresponding `hosts.ini` before running any playbook.

For production, the preferred approach is to use the AWS EC2 dynamic inventory plugin configured in `ansible.cfg` so that host IPs are resolved automatically from AWS tags rather than maintained manually.

### Variables and group_vars

Environment-specific variables belong in `ansible/group_vars/dev.yml`, `staging.yml`, or `prod.yml`. Variables shared across all environments go in `all.yml`. Do not put secrets or plaintext passwords in any of these files — use SSM Parameter Store lookups instead (see [Secrets and Sensitive Values](#secrets-and-sensitive-values)).

### Roles

Each role is single-responsibility. The existing roles are:

- `common` — baseline OS setup, packages, users, hardening. Runs first on every host.
- `postgresql` — install, init, user and database creation.
- `nginx` — install, write site configs from templates, reload on config change via handlers.
- `app_deploy` — pull app code, write `.env` files from SSM values using Jinja2 templates, configure PM2 ecosystem, restart services.

If you are adding support for a new service (e.g., Redis, Milvus), create a new role for it. Do not add tasks for an unrelated service into an existing role. Each role must be idempotent — running it twice on the same host must produce no unintended changes on the second run.

### Templates

Jinja2 templates live in `roles/<role>/templates/` and use the `.j2` extension. Variables injected into templates must be defined in `group_vars` or fetched from SSM — never hardcoded in the template itself. When adding a new variable to a template, document it in the role's `README.md` (create one if it does not exist).

### Testing a playbook before running it for real

Always do a dry run first:

```bash
ansible-playbook ansible/playbooks/site.yml \
  -i ansible/inventories/dev/hosts.ini \
  --check --diff
```

`--check` simulates the run without making changes. `--diff` shows exactly what would change in files. Only after reviewing this output should you run without `--check`.

For targeted runs during development, use `--tags` or `--limit` to scope execution:

```bash
# only run the nginx role
ansible-playbook ansible/playbooks/site.yml \
  -i ansible/inventories/dev/hosts.ini \
  --tags nginx

# only run against a specific host
ansible-playbook ansible/playbooks/site.yml \
  -i ansible/inventories/dev/hosts.ini \
  --limit app-server-1
```

### Rollback

`ansible/playbooks/rollback.yml` exists for controlled rollbacks. Understand what it does before invoking it — it is not an undo button and may have prerequisites depending on what is being rolled back.

---

## Working with GitHub Actions Workflows

There are three workflows:

**`terraform.yml`** — triggers on PRs and merges that touch `terraform/`. On a PR it runs `plan` and posts the output as a comment. On merge to `dev`, `staging`, or `main`, it runs `apply` against the corresponding environment. You do not manually trigger this.

**`ansible.yml`** — triggers manually (`workflow_dispatch`) or automatically after `terraform.yml` completes a successful apply, since a new or changed EC2 instance needs to be configured. It runs `site.yml` against the affected environment's inventory.

**`drift-detection.yml`** — runs on a schedule. Runs `terraform plan` against all environments and alerts if there is drift between the state file and actual AWS resources. If drift is detected, open a PR to reconcile it — do not fix drift by manually changing AWS resources.

When modifying a workflow file, test changes on a branch first. Workflow changes that break the pipeline block everyone. Use `act` locally to validate workflow syntax before pushing if possible.

---

## Environment Promotion

Changes move through environments in order: **dev → staging → prod**. Skipping environments is not permitted except in a declared incident with documented justification.

The promotion process:

1. Change is developed and validated in dev (Terraform plan reviewed, Ansible dry-run checked).
2. PR opened from feature branch into `dev`, reviewed and merged.
3. Pipelines run automatically. Confirm no errors before promoting.
4. PR opened from `dev` into `staging`. At least one review required.
5. After staging is validated (smoke tests, drift-detection clean), PR opened from `staging` into `main`.
6. Prod apply is gated — the `terraform.yml` workflow requires explicit approval from a designated reviewer before applying to prod.

---

## Secrets and Sensitive Values

This repository must never contain:

- AWS access keys or secret keys
- Database passwords or connection strings
- API keys or tokens
- Private SSH keys
- `.env` files with real values

All secrets are stored in **AWS SSM Parameter Store** as `SecureString` parameters. Ansible fetches them at runtime using the `amazon.aws.ssm_parameter` lookup in `group_vars` or directly in tasks. Terraform reads them via the `aws_ssm_parameter` data source where needed.

The naming convention for SSM parameters is:

```
/<environment>/<service>/<key>

/prod/postgresql/app_password
/prod/backend/secret_key
/staging/nginx/ssl_cert_arn
```

If you need to add a new secret, add the SSM parameter manually (or via Terraform in the `ssm` module if it is non-sensitive metadata) and reference it by path in the appropriate `group_vars` or task. Document the parameter path in the PR description.

GitHub Actions secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, etc.) are managed by the repository owner. If a workflow needs a new secret, request it rather than adding workarounds.

---

## Pull Request Standards

Every PR must include:

- **What changed** — a clear description of what infrastructure or configuration is being modified and why.
- **Environments affected** — explicitly state which environments (dev / staging / prod) this change touches.
- **Terraform plan output** — paste the relevant section of `terraform plan` output for any Terraform change. The pipeline also posts this automatically, but a human summary in the description is required.
- **Ansible dry-run output** — paste `--check --diff` output for any Ansible change.
- **Rollback plan** — how to revert this change if something goes wrong after apply.

PRs that touch prod-facing resources require at least one approval from a maintainer. PRs that only touch dev or documentation can be self-merged after CI passes, but a second pair of eyes is still encouraged.

Keep PRs small and focused. A PR that adds a new Terraform module, modifies an Ansible role, and updates two workflows simultaneously is hard to review safely. Split them if possible.

---

## Commit Message Convention

Follow the Conventional Commits specification:

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `chore`, `docs`, `ci`, `refactor`, `test`

Scopes map to the areas of this repo: `terraform`, `ansible`, `workflows`, `modules`, `roles`, `scripts`

Examples:

```
feat(ansible): add postgresql role with SSM-backed credentials
fix(terraform): correct security group ingress rule for staging RDS
chore(modules): upgrade aws provider constraint to ~> 5.50
ci(workflows): add manual trigger to ansible.yml for targeted runs
docs: update CONTRIBUTING with rollback procedure
```

The short description is lowercase, imperative, no trailing period.

---

## What Requires a Review

The following always require at least one explicit approval before merge, regardless of branch:

- Any change to `terraform/environments/prod/`
- Any change to `terraform/modules/` that modifies variable interfaces or outputs
- Any change to `ansible/playbooks/rollback.yml`
- Any change to `ansible/roles/common/` since it runs on every host
- Any change to `.github/workflows/` that affects prod apply logic or approval gates
- Rotating or changing SSM parameter paths referenced by running services

---

## What You Must Never Do

- **Never run `terraform destroy`** on staging or prod without explicit sign-off documented in a GitHub issue.
- **Never edit tfstate directly.** If state is broken, open an issue and work through `terraform state` subcommands with a second person present.
- **Never SSH into a server and make manual changes** that are not reflected back in Ansible. If you find yourself doing this, it means a role is missing coverage — add it.
- **Never commit a real `.env` file, private key, or credential** to this repository. If it happens accidentally, treat it as a secret rotation incident immediately — rewriting git history is not sufficient since the secret may have been cloned or cached.
- **Never apply to prod on a Friday afternoon.**
