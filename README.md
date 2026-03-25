# vedico-infra

Infrastructure-as-Code for the Vedico platform.  
**Stack:** Terraform (AWS) · Ansible · GitHub Actions  
**Environments:** `dev` → `staging` → `prod`

---

## Repository Structure

```
vedico-infra/
├── terraform/
│   ├── modules/                   # Reusable modules
│   │   ├── networking/            # VPC, subnets, SGs
│   │   ├── compute/               # EC2, EIP, key pair
│   │   ├── storage/               # S3 app bucket
│   │   └── iam/                   # EC2 role, S3 PoLP
│   └── environments/
│       ├── dev/                   # tfvars + backend + main
│       ├── staging/
│       └── prod/
│
├── ansible/
│   ├── inventories/{dev,staging,prod}/hosts.ini
│   ├── group_vars/                # all.yml + per-env overrides
│   ├── roles/
│   │   ├── common/                # OS packages, Node, Go, Python, UFW
│   │   ├── postgresql/            # PG install, DB, user, PostGIS
│   │   ├── nginx/                 # vhost template, Certbot TLS
│   │   └── app_deploy/            # clone, build, .env, PM2
│   └── playbooks/
│       ├── site.yml               # Full provision (run once)
│       ├── deploy.yml             # App deploy only (CI)
│       └── rollback.yml           # Revert to previous commit
│
├── scripts/
│   └── bootstrap-state.sh         # One-time S3 + DynamoDB setup
│
└── .github/workflows/
    ├── terraform.yml              # Plan on PR, apply on merge
    ├── ansible.yml                # Provision/deploy via Ansible
    └── drift-detection.yml        # Nightly drift alerts
```

---

## One-Time Bootstrap

### 1. Create S3 state bucket + DynamoDB lock table

```bash
chmod +x scripts/bootstrap-state.sh
./scripts/bootstrap-state.sh ap-south-1 vedico
```

Update the `bucket` value in each `terraform/environments/*/backend.tf`  
with the actual bucket name printed by the script.

### 2. Configure AWS OIDC for GitHub Actions

Create an IAM OIDC provider for `token.actions.githubusercontent.com` and  
an IAM role per environment that trusts it. Add the role ARNs as GitHub  
repository secrets:

| Secret | Value |
|--------|-------|
| `AWS_ROLE_ARN_DEV` | arn:aws:iam::ACCOUNT:role/vedico-dev-github |
| `AWS_ROLE_ARN_STAGING` | arn:aws:iam::ACCOUNT:role/vedico-staging-github |
| `AWS_ROLE_ARN_PROD` | arn:aws:iam::ACCOUNT:role/vedico-prod-github |

### 3. Add all secrets to GitHub

```
EC2_PUBLIC_KEY_DEV / STAGING / PROD      # SSH public key content
EC2_SSH_PRIVATE_KEY_DEV / STAGING / PROD # SSH private key (for Ansible)
PG_PASSWORD_DEV / STAGING / PROD
BACKEND_APP_KEY_DEV / STAGING / PROD
INTERNAL_NOTIFY_TOKEN_DEV / STAGING / PROD
AWS_ACCESS_KEY_ID                        # App-level S3 access
AWS_SECRET_ACCESS_KEY
GITHUB_DEPLOY_KEY                        # Private key for deploy key on app repos
```

---

## Day-to-Day Operations

### Provision a fresh server (run once per environment)

```bash
# From your local machine
cd ansible
ansible-playbook \
  -i inventories/dev/hosts.ini \
  playbooks/site.yml \
  --extra-vars "pg_password=SECRET backend_app_key=SECRET ..."
```

### Deploy app only

```bash
ansible-playbook \
  -i inventories/dev/hosts.ini \
  playbooks/deploy.yml \
  --extra-vars "git_branch=main"
```

### Rollback

```bash
ansible-playbook -i inventories/prod/hosts.ini playbooks/rollback.yml
```

### Terraform — manual plan/apply

```bash
cd terraform/environments/dev
terraform init
terraform plan -var="ec2_public_key=$(cat ~/.ssh/vedico-dev.pub)"
terraform apply -var="ec2_public_key=$(cat ~/.ssh/vedico-dev.pub)"
```

---

## CI/CD Flow

```
PR opened
  └─► terraform validate + fmt check (all envs)
  └─► terraform plan → posted as PR comment

Merge to main (terraform/** changed)
  └─► apply dev  (automatic)
  └─► apply staging  (requires manual approval in GitHub)
  └─► apply prod     (requires manual approval in GitHub)

Merge to main (ansible/** changed)
  └─► ansible deploy → dev  (automatic)
  └─► ansible deploy → staging/prod  (workflow_dispatch, manual)

Nightly 02:00 UTC
  └─► terraform plan --detailed-exitcode on all envs
  └─► opens GitHub Issue if drift detected
```

---

## Environment CIDRs

| Env     | VPC CIDR      | Public Subnets           | Private Subnets          |
|---------|---------------|--------------------------|--------------------------|
| dev     | 10.10.0.0/16  | 10.10.1–2.0/24           | —                        |
| staging | 10.20.0.0/16  | 10.20.1–2.0/24           | —                        |
| prod    | 10.30.0.0/16  | 10.30.1–2.0/24           | 10.30.10–11.0/24         |

---

## Security Notes

- **SSH** to prod is restricted to VPN CIDRs only (`ssh_allowed_cidrs`).  
  Use AWS SSM Session Manager as the preferred access method.
- **Secrets** are never stored in this repo. All sensitive values flow  
  through GitHub Actions secrets → Ansible `--extra-vars` → server `.env` files (mode 0600).
- **Terraform state** is AES-256 encrypted at rest, versioned, and  
  DynamoDB-locked to prevent concurrent applies.
- **IMDSv2** is enforced on all EC2 instances.
- **UFW** blocks all inbound except 22/80/443; fail2ban protects SSH.

