# Test Deploy Ansible Playbook v1

This action setups all necesary OpenStack resources for a user-specfied Ansible Playbook to run, gather deployment details and uploads them as artifacts for audit or post-processing.

## Features
- Provisions a test OpenStack compute instance, based on user-provided specifications
- Attaches a floating IP address to the test instance
- Configures the test instance with user-defined Ansible Playbook, including required Ansible Roles and any given extra variables
- Generates an execution summary (rendered in the GitHub UI), as well as machine-friendly run artifacts.
- Cleans up all used resources upon completion

## Prerequisites

1. Acquire OpenStack application credentials with enough permissions to modify compute instances
2. Extract the following attributes from your app credentials and store them within your repository's GitHub secrets:
    - `OS_AUTH_URL`
    - `OS_REGION_NAME`
    - `OS_APPLICATION_CREDENTIAL_ID`
    - `OS_APPLICATION_CREDENTIAL_SECRET`
4. Create an ssh keypair
3. Upload the public ssh key to OpenStack
5. Within your repository's GitHub secrets, store the valud of the private ssh key as:
    - `ANSIBLE_SSH_PRIVATE_KEY`


## Usage

```yaml
name: Test Deploy Ansible Playbook

on:
  workflow_dispatch:

permissions:
  contents: read
  actions: write

jobs:
  test-deploy-ansible-playbook:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Test deployment
        uses: ewcloud/ewc-gh-action-test-deploy-ansible-playbook@v1
        with:
          os-auth-url: '${{ secrets.OS_AUTH_URL }}'
          os-region-name: '${{ secrets.OS_REGION_NAME }}'
          os-application-credential-id: '${{ secrets.OS_APPLICATION_CREDENTIAL_ID }}'
          os-application-credential-secret: '${{ secrets.OS_APPLICATION_CREDENTIAL_SECRET }}'
          os-external-network-name: 'external'
          os-private-network-name: 'private'
          os-security-group-name: 'ssh'
          os-flavor-name: 'eo1.small'
          os-image-name: 'ubuntu-24.04-20250604102601'
          os-keypair-name: 'github-keypair'
          ansible-user: 'ubuntu'
          ansible-ssh-private-key: '${{ secrets.ANSIBLE_SSH_PRIVATE_KEY }}'
          path-to-main-file: 'site.yml'
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| os-auth-url | URL pointing to OpenStack authentication API | `string` | n/a | yes |
| os-region-name | OpenStack region name. Example: `RegionOne` | `string` | n/a | yes |
| os-application-credential-id | OpenStack application credential ID | `string` | n/a | yes |
| os-application-credential-secret | OpenStack application credential secret | `string` | n/a | yes |
| os-external-network-name | Name of the external OpenStack network for floating IPs | `string` | n/a | yes |
| os-private-network-name | Name of the private OpenStack network name to attach the test compute instance to | `string` | n/a | yes |
| os-security-group-name | Name of the OpenStack security group assgined to the test compute instance | `string` | n/a | yes |
| os-keypair-name | Name of the pre-uploaded public ssh keypair in OpenStack | `string` | n/a | yes |
| os-flavor-name | Name the OpenStack flavor to use for the instance | `string` | n/a | yes |
| os-image-name | Name of the image to use for the OpenStack compute instance | `string` | n/a | yes |
| instance-name-prefix | Prefix for the OpenStack compute instance (will prepend to the GitHub run id) | `string` | `github` | no |
| ansible-user | Operative system user which Ansible impersonates when connecting to the test compute intance | `string` | n/a | yes |
| ansible-ssh-private-key | Value of the private ssh keypair for compute instance access | `string` | n/a | yes |
| path-to-main-file | Path to main file for the Ansible Playbook execution. Example: `playbooks/ssh-bastion-flavour/ssh-bastion-flavour.yml` | `string` | n/a | yes |
| path-to-requirements-file | Path to requirements file needed for the Ansible Playbook. Example: `playbooks/ssh-bastion-flavour/requirements.yml` | `string` | `""` | no |
| input-spec-json | Input values for the Ansible Playbook, in JSON format | `string` | `{}` | no |

## Outputs

| Name | Description | Type |
|------|-------------|------|
| artifact_path | Path where artifacts were written in the workflow workspace | `string` |

## Development

### TODOs
- Support running on user-defined Python and Ansible versions
- Include OpenStack project name in summary
- Add proper SSH status polling (with netcat or similar utility)