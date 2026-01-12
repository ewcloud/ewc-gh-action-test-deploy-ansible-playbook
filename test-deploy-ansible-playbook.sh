#!/usr/bin/env bash
set -eou pipefail

# NOTE: For tracking status and graceful failure
TERRAFORM_STATUS="failing"
ANSIBLE_STATUS="failing"
GREEN_LIGHT="🟢"
RED_LIGHT="🔴"

# --- Step 1 ---
echo "Validate input spec format (Ansible extra vars)"
if [ -z "$INPUT_SPEC_JSON" ]; then
  INPUT_SPEC_JSON="{}"
fi
if ! printf "%s" "$INPUT_SPEC_JSON" | jq -e . >/dev/null 2>&1; then
  echo "::error::input-spec-json is invalid JSON. Got: '$INPUT_SPEC_JSON'"
  exit 1
fi

# --- Step 2 ---
# NOTE: GitHub mounts workspace at /github/workspace
echo "Gather environment facts"
PYTHON_VERSION="$(python3 --version)"
ANSIBLE_VERSION="$(pip freeze | grep 'ansible' | awk -F'==' '{print $1, $2}')"
PLAYBOOK_PATH="${GITHUB_WORKSPACE}/${PATH_TO_MAIN_FILE}"

# --- Step 3 ---
echo "Create artifact directory"
ARTIFACTS_DIR="${GITHUB_WORKSPACE}/artifacts"
mkdir -p "$ARTIFACTS_DIR"

# --- Step 4 ---
echo "Write out extra vars"
EXTRA_VARS_FILE="${GITHUB_WORKSPACE}/extra_vars.json"
printf "%s" "$INPUT_SPEC_JSON" | jq . > "$EXTRA_VARS_FILE"

# --- Step 5 ---
echo "Setup SSH private key"
ANSIBLE_SSH_PRIVATE_KEY_FILE="/tmp/.ssh/id_github"
mkdir -p /tmp/.ssh

if [ -z "${ANSIBLE_SSH_PRIVATE_KEY:-}" ]; then
  echo "::error::Missing ANSIBLE_SSH_PRIVATE_KEY"
  exit 1
fi

printf "%s" "$ANSIBLE_SSH_PRIVATE_KEY" > "$ANSIBLE_SSH_PRIVATE_KEY_FILE"
chmod 600 "$ANSIBLE_SSH_PRIVATE_KEY_FILE"
eval "$(ssh-agent -s)"
ssh-add $ANSIBLE_SSH_PRIVATE_KEY_FILE

# --- Step 6 ---
echo "Create Terraform variables file"
cat > /tmp/vars.tfvars <<EOF
image_name            = "${OS_IMAGE_NAME}"
flavor_name           = "${OS_FLAVOR_NAME}"
app_name              = "${INSTANCE_NAME_PREFIX}"
instance_name         = "vm"
instance_index        = ${GITHUB_RUN_ID}
networks              = ["${OS_PRIVATE_NETWORK_NAME}"]
external_network_name = "${OS_EXTERNAL_NETWORK_NAME}"
security_groups       = ["${OS_SECURITY_GROUP_NAME}"]
keypair_name          = "${OS_KEYPAIR_NAME}"
instance_has_fip      = true
EOF

# --- Step 7 ---
echo "Download Terraform module"
TF_DIR="/tmp/tf-module"
TF_MODULE_URL="https://github.com/ewcloud/ewc-tf-module-openstack-compute.git"
TF_MODULE_REF="1.4.0"
rm -rf "$TF_DIR"
git clone "$TF_MODULE_URL" "$TF_DIR"
cd "$TF_DIR"
git checkout "$TF_MODULE_REF"

# --- Step 8 ---
echo "Apply Terraform"
terraform init -input=false
set +e
terraform apply -auto-approve -var-file=/tmp/vars.tfvars
TF_APPLY_EXIT=$?
set -e

if [ "$TF_APPLY_EXIT" -eq 0 ]; then
  TERRAFORM_STATUS="passing"
else
  TERRAFORM_STATUS="failing"
fi

# --- Step 9 ---
echo "Verify Terraform output"
TF_OUTPUT_JSON="$(terraform output -json instance || true)"

# --- Step 10 ---
echo "Get IP address of the test instance"
FLOATING_IP=""
if [ -n "$TF_OUTPUT_JSON" ]; then
  FLOATING_IP=$(printf "%s" "$TF_OUTPUT_JSON" | jq .floating_ip | tr -d '"')
fi

# --- Step 11 ---
if [ -n "$FLOATING_IP" ]; then
  echo "Wait for SSH on instance at ${FLOATING_IP}"
  SSH_WAIT_SECS=120
  sleep $SSH_WAIT_SECS
fi

# --- Step 12 ---
echo "Prepare inventory"
INVENTORY_FILE="${GITHUB_WORKSPACE}/inventory.yml"
cat > "$INVENTORY_FILE" <<EOF
all:
  hosts:
    test_instance:
      ansible_python_interpreter: /usr/bin/python3
      ansible_host: ${FLOATING_IP}
      ansible_ssh_private_key_file: ${ANSIBLE_SSH_PRIVATE_KEY_FILE}
      ansible_user: ${ANSIBLE_USER}
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

# --- Step 13 ---
echo "Install required Ansible Roles (if any)"
if [ -n "$PATH_TO_REQUIREMENTS_FILE" ] && [ -f "${GITHUB_WORKSPACE}/${PATH_TO_REQUIREMENTS_FILE}" ]; then
  ansible-galaxy install -r "${GITHUB_WORKSPACE}/${PATH_TO_REQUIREMENTS_FILE}"
fi

# --- Step 14 ---
echo "Run Ansible"
ANSIBLE_CMD=(ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_PATH" --extra-vars "@${EXTRA_VARS_FILE}")

ANSIBLE_EXIT_CODE=0
set +e
"${ANSIBLE_CMD[@]}"
ANSIBLE_EXIT_CODE=$?
set -e

if [ "$ANSIBLE_EXIT_CODE" -eq 0 ]; then
  ANSIBLE_STATUS="passing"
fi

# --- Step 15 ---
echo "Write execution summary"
add_summary() {
  # NOTE: Helper for appending markdown
  printf "%s\n" "$1" >> "$GITHUB_STEP_SUMMARY"
}

add_summary "# EWC Community Hub Item Test Summary"
add_summary "- **Run ID:** \`${GITHUB_RUN_ID}\`"
add_summary "- **Repository:** \`${GITHUB_REPOSITORY}\`"
add_summary "- **Branch/Tag:** \`${GITHUB_REF_NAME}\`"
add_summary "- **Entrypoint:** \`${PATH_TO_MAIN_FILE}\`"
add_summary "## Status"
add_summary "### Instance Configuration"
if [ "$ANSIBLE_STATUS" = "failing" ]; then
  add_summary "- **Ansible Status:** \`${ANSIBLE_STATUS}\` ${RED_LIGHT}"
else
  add_summary "- **Ansible Status:** \`${ANSIBLE_STATUS}\` ${GREEN_LIGHT}"
fi
add_summary "- **Ansible Exit Code:** \`${ANSIBLE_EXIT_CODE}\`"
add_summary "### Instance Provisioning"
if [ "$TERRAFORM_STATUS" = "failing" ]; then
  add_summary "- **Terraform Status:** \`${TERRAFORM_STATUS}\` ${RED_LIGHT}"
else
  add_summary "- **Terraform Status:** \`${TERRAFORM_STATUS}\` ${GREEN_LIGHT}"
fi
add_summary "- **Terraform Exit Code:** \`${TF_APPLY_EXIT}\`"
add_summary "## Environment Details"
add_summary "### Prerequisites"
add_summary "- \`$PYTHON_VERSION\`"
add_summary "- \`$ANSIBLE_VERSION\`"
add_summary "### Item"
if [ -f "${GITHUB_WORKSPACE}/${PATH_TO_REQUIREMENTS_FILE}" ]; then
  add_summary "#### Dependencies"
  add_summary "\`\`\`yaml"
  cat "${GITHUB_WORKSPACE}/${PATH_TO_REQUIREMENTS_FILE}" >> "$GITHUB_STEP_SUMMARY"
  add_summary "\`\`\`"
fi
if [ "$INPUT_SPEC_JSON" != "{}" ]; then
  add_summary "#### Inputs"
  add_summary "\`\`\`json"
  cat "$EXTRA_VARS_FILE" >> "$GITHUB_STEP_SUMMARY"
  add_summary "\`\`\`"
fi
add_summary "### Infrastructure"
add_summary "- **OpenStack Instance:** \`${INSTANCE_NAME_PREFIX}-vm-${GITHUB_RUN_ID}\`"
add_summary "- **OpenStack Image:** \`$OS_IMAGE_NAME\`"
add_summary "- **OpenStack Flavor:** \`$OS_FLAVOR_NAME\`"
add_summary "- **OpenStack Floating IP:** \`${FLOATING_IP:-none}\`"
add_summary "---"
add_summary "_Summary Auto-generated by \"Test Deploy Ansible Playbook\" GitHub Action_"


# --- Step 16 ---
echo "Collect artifacts"
echo "{\"terraform_exit_code\":\"$TF_APPLY_EXIT\"}" > "$ARTIFACTS_DIR/tf_exit_code.json"
terraform output -json > "$ARTIFACTS_DIR/tf_output.json" || true
echo "{\"ansible_exit_code\":\"$ANSIBLE_EXIT_CODE\"}" > "$ARTIFACTS_DIR/ansible_exit_code.json"
cp $EXTRA_VARS_FILE "$ARTIFACTS_DIR/extra_vars.json"

# NOTE: Download the /sbom.json file and re-upload as artifact, if available within the test instance
if [ -n "$FLOATING_IP" ]; then
  scp -i "$ANSIBLE_SSH_PRIVATE_KEY_FILE" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${ANSIBLE_USER}@${FLOATING_IP}:/sbom.json" "$ARTIFACTS_DIR/" 2>/dev/null || true
fi

cp $GITHUB_STEP_SUMMARY "$ARTIFACTS_DIR/summary.md"

# --- Step 17 ---
echo "Write GitHub action outputs"
echo "artifact-path=$ARTIFACTS_DIR" >> "$GITHUB_OUTPUT"

# --- Step 18 ---
echo "Teardown test instance"
terraform destroy -auto-approve -var-file=/tmp/vars.tfvars

# -- Step 19 ---
echo "Re-rasing test errors (if any)"
if [ "$TERRAFORM_STATUS" = "failing" ] || [ "$ANSIBLE_STATUS" = "failing" ]; then
  echo "::error::One or more failures caught during testing. See the summary or logs for details"
  exit 1
fi