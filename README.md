# autobahn-vpm-gha-packer

This repository contains GitHub Action workflows (`.github/workflows/`), Packer
pipelines (`packer/`), and Ansible playbooks (`ansible/`) in support of the
Autobahn VPM POV.

## Requirements

The workflows rely on a number of GitHub Action secrets and variables. In this
section we'll cover those requirements.

### GitHub Action variables

The following GitHub Action variables must be defined:

| Variable Name                 | Description                                       |
| ----------------------------- | ------------------------------------------------- |
| `AWS_GITHUB_ROLE_ARN`         | AWS IAM Role to assume                            |
| `AWS_REGION`                  | AWS region for AMI images                         |
| `HCP_PACKER_BUCKET_BASE_NAME` | The name of the Packer bucket to create           |
| `PACKER_IMAGE_OWNER`          | Metadata for the Packer images                    |
| `HCP_PROJECT_ID`              | The HCP Project where the Packer registry resides |

You may set those variables manually, or using the `gh` CLI. To use the `gh` CLI, first
create a file with the variables defined (named `repo_vars.env` for example):

```env
AWS_REGION=<insert target AWS region>
HCP_PACKER_BUCKET_BASE_NAME=<insert HCP Packer bucket name>
HCP_PROJECT_ID=<insert HCP project ID for the HCP Packer registry>
PACKER_IMAGE_OWNER=<insert image owner>
AWS_GITHUB_ROLE_ARN=<insert AWS IAM role to assume>
```

Then, execute the command from the git repository directory on your system:

```bash
gh variable set -f repo_vars.env
```

### GitHub Action secrets

The following GitHub Action secrets must be defined:

| Secret Name         | Description                                        |
| ------------------- | -------------------------------------------------- |
| `HCP_CLIENT_ID`     | HCP Service Principal Client ID                    |
| `HCP_CLIENT_SECRET` | HCP Service Principal Client Secret                |
| `GH_PAT`            | GitHub PAT with authorization to trigger workflows |

Additional secrets are needed based on how access to AWS is configured. If using
static credentials, the following additional secrets could be defined:

| Secret Name             | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `AWS_ACCESS_KEY_ID`     | ID of the AWS access key associated with an IAM account |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key associated with an IAM account    |
| `AWS_SESSION_TOKEN`     | AWS session token                                       |

See the documentation about the ["Configure AWS Credentials" Action for GitHub action](https://github.com/marketplace/actions/configure-aws-credentials-action-for-github-actions) for recommended methods of authenticating with AWS.

## Images

There are four example flows demonstrated in this repo:

- x86_64 Ubuntu 22.04 base image sourced from Amazon with CIS Level 1 benchmark applied
- x86_64 Ubuntu base image with NGINX additionally deployed using Ansible
- x86_64 Ubuntu base image with MySQL additionally deployed using Ansible
- x86_64 RHEL 9.3 base image sourced from Amazon with CIS Level 1 benchmark applied

Each resulting image is deployed into the configured AWS account as an AMI
available for compute provisioning and registered with HCP Packer.

### CIS Level 1 Benchmark

The benchmark remediation may not produce 100% CIS Level 1 Benchmark compliance
due to AWS/AMI requirements. Results from each mitigation process are available
for inspection if needed at `/var/lib/usg`.

## Customizing

Customization of this repository is relatively simple and can be achieved by
duplicating and modifying the templated pipelines and/or playbooks. The base
image can easily be supplemented with an additional `shell` provisioner or by
uncommenting the `ansible` provisioner to include security agents or other
customer-specific requirements. There is a corresponding empty playbook and
requirements file for the base image that is unused by default.

### GitHub Actions Workflows

The three workflows defined in `.github/workflows` are responsible for running
Packer (with HCP Packer integration). The `base` image workflows are triggered
based on either a monthly cron schedule, or by a push to the repository. The
downstream NGINX and MySQL pipelines are triggered by webhooks that the base
workflow executes upon successful completion a new build. Sensible defaults for
`paths` and/or `ignore-paths` have been set on these workflows to avoid
excessive pipeline execution.
