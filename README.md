# Test Deploy Ansible Playbook v2

This GitHub Action setups all necessary OpenStack resources for a Ansible Playbook to run,  executes it and reports about its success/failure in a nice looking summary (within GitHub UI), as well as machine-friendly artifacts for postprocessing.

Runs with user-defined `Python` and `Ansible` versions, extra variable inputs and any `Ansible Roles` a test scenario may require.

## What's new

- Added compatibility with the [ewc-community-hub](https://github.com/ewcloud/ewc-community-hub) repository to enable upstream test orchestration and by enforcing naming and formatting convention of workflow inputs.

## Copyright and License
Copyright © EUMETSAT 2026.

The provided code and instructions are licensed under [MIT license](./LICENSE).
They are intended to automate the setup of an environment that includes
third-party software components.
The usage and distribution terms of the resulting environment are
subject to the individual licenses of those third-party libraries.

Users are responsible for reviewing and complying with the licenses of
all third-party components included in the environment.

Contact [EUMETSAT](http://www.eumetsat.int) for details on the usage and distribution terms.

## Prerequisites

* Get OpenStack API credentials (see [How to request OpenStack Application Credentials](https://confluence.ecmwf.int/x/TiRNH) section of the EWC documentation)
* Extract the following attributes from your app credentials and store them within your repository's GitHub secrets (see [Creating secrets for a repository](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets#creating-secrets-for-a-repository) section of the GitHub documentation):
    - `OS_AUTH_URL`
    - `OS_REGION_NAME`
    - `OS_APPLICATION_CREDENTIAL_ID`
    - `OS_APPLICATION_CREDENTIAL_SECRET`
* Create an SSH keypair (see [Generating a new SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=linux#generating-a-new-ssh-key) section of the GitHub documentation )
* Add you SSH public key to OpenStack (see [Import SSH Key](https://confluence.ecmwf.int/x/TyRNH) section of the EWC documentation).
* Once more, update your repository's GitHub secrets to include the value of the private ssh key as:
    - `ANSIBLE_SSH_PRIVATE_KEY`


## Usage
>💡 For live usage examples in EWC Community Hub's context, checkout these [ECMWF test workflow](https://github.com/ewcloud/ewc-ansible-playbook-flavours-and-provisioning/blob/main/.github/workflows/test-ecmwf.yml) and [EUMETSAT test workflow](https://github.com/ewcloud/ewc-ansible-playbook-flavours-and-provisioning/blob/main/.github/workflows/test-eumetsat.yml) definitions.

```yaml
# .github/workflows/test.yml
---
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
        id: test-deployment
        uses: ewcloud/ewc-gh-action-test-deploy-ansible-playbook@v2
        with:
          osAuthUrl: '${{ secrets.OS_AUTH_URL }}'
          osRegionName: '${{ secrets.OS_REGION_NAME }}'
          osApplicationCredentialId: '${{ secrets.OS_APPLICATION_CREDENTIAL_ID }}'
          osApplicationCredentialSecret: '${{ secrets.OS_APPLICATION_CREDENTIAL_SECRET }}'
          osExternalNetworkName: 'external'
          osPrivateNetworkName: 'private'
          osSecurityGroupName: 'ssh'
          osFlavorName: 'eo1.small'
          osImageName: 'ubuntu-24.04-20250604102601'
          osKeypairName: 'github-keypair'
          ansibleUser: 'ubuntu'
          ansibleSshPrivateKey: '${{ secrets.ANSIBLE_SSH_PRIVATE_KEY }}'
          pathToMainFile: 'site.yml'

      - name: Upload test deployment result
        uses: actions/upload-artifact@v4
        with:
          name: artifacts_${{ github.run_id }}
          path: ${{ steps.test-deployment.outputs.artifactPath }}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ansibleSshPrivateKey | Value of the private ssh keypair for compute instance access | `string` | n/a | yes |
| ansibleUser | Operative system user which Ansible impersonates when connecting to the test compute instance | `string` | n/a | yes |
| ansibleVersion | Ansible version to be used during testing (must be supported by the specified Python version) | `string` | `10.7.0` | yes |
| osApplicationCredentialId | OpenStack application credential ID | `string` | n/a | yes |
| osApplicationCredentialSecret | OpenStack application credential secret | `string` | n/a | yes |
| osAuthUrl | URL pointing to OpenStack authentication API | `string` | n/a | yes |
| osExternalNetworkName | Name of the external OpenStack network for floating IPs | `string` | n/a | yes |
| osFlavorName | Name the OpenStack flavor to use for the instance | `string` | n/a | yes |
| osImageName | Name of the image to use for the OpenStack compute instance | `string` | n/a | yes |
| osKeypairName | Name of the pre-uploaded public ssh keypair in OpenStack | `string` | n/a | yes |
| osPrivateNetworkName | Name of the private OpenStack network name to attach the test compute instance to | `string` | n/a | yes |
| osRegionName | OpenStack region name. Example: `RegionOne` | `string` | n/a | yes |
| osSecurityGroupName | Name of the OpenStack security group assigned to the test compute instance | `string` | n/a | yes |
| pathToMainFile | Path to main file for the Ansible Playbook execution. Example: `playbooks/ssh-bastion-flavour/ssh-bastion-flavour.yml` | `string` | n/a | yes |
| pathToRequirementsFile | Path to requirements file needed for the Ansible Playbook. Example: `playbooks/ssh-bastion-flavour/requirements.yml` | `string` | n/a | no |
| pythonVersion | Python version to be used during testing | `string` | `3.9.25` | yes |
| inputSpecJson | Input values for the Ansible Playbook, in JSON format. Example: `{"fail2ban_whitelisted_ip_ranges":""}` | `string` | n/a | no |
| instanceNamePrefix | Prefix for the OpenStack compute instance (will prepend to the GitHub run id) | `string` | `github` | yes |

## Outputs

| Name | Description | Type |
|------|-------------|------|
| artifactPath | Path where artifacts were written in the workflow workspace | `string` |

## Dependencies

| Name | Home URL |
| ----- | -----|
| ewc-tf-module-openstack-compute | https://github.com/ewcloud/ewc-tf-module-openstack-compute |


## Contributing

Thanks for taking the time to join our community and start contributing!
Please make sure to:
* Familiarize yourself with our [Code of Conduct](./CODE_OF_CONDUCT.md) before
contributing.
* See [CONTRIBUTING.md](./CONTRIBUTING.md) for instructions on how to request
or submit changes.

## Authors

[European Weather Cloud](http://support.europeanweather.cloud/)
<[support@europeanweather.cloud](mailto:support@europeanweather.cloud)>

## Development

### TODOs
- Add proper SSH status polling (with netcat or similar utility)