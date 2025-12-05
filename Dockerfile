ARG PYTHON_VERSION=3.10
FROM python:${PYTHON_VERSION}-slim

ARG PYTHON_VERSION
ARG ANSIBLE_VERSION=10.7.0
ARG TERRAFORM_VERSION=1.14.1

ENV DEBIAN_FRONTEND=noninteractive
ENV TF_IN_AUTOMATION=true

# Install system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    unzip \
    git \
    openssh-client \
    dnsutils \
    jq \
    yq \
    curl && \
    rm -rf /var/lib/apt/lists/*

# Install Terraform (download official binary)
RUN curl -fsSL -o /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip  https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  unzip /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin && \
  rm -f /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install Python packages (Ansible + OpenStack client)
RUN pip install --upgrade pip
RUN pip install --no-cache-dir \
    python-openstackclient \
    "ansible==${ANSIBLE_VERSION}"

# Add action files
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]