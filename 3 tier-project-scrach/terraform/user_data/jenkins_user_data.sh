#!/bin/bash
set -euo pipefail

# Non-interactive installer for Jenkins node (Amazon Linux 2 compatible)

yum update -y || true

# Install Java 11 if not present (Jenkins supports Java 11+)
if ! java -version >/dev/null 2>&1; then
	yum install -y java-11-openjdk-devel
fi

# Install git and docker
yum install -y git docker
systemctl enable --now docker
usermod -a -G docker ec2-user || true

# Configure Jenkins repository and import GPG key
curl -fsSL https://pkg.jenkins.io/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key || true

# Install Jenkins (non-interactive). If install fails, capture output in log.
if ! yum install -y jenkins; then
	journalctl -u jenkins --no-pager || true
fi

# Ensure systemd knows about new unit files and start Jenkins if available
systemctl daemon-reload || true
if systemctl list-unit-files | grep -q "jenkins.service"; then
	systemctl enable --now jenkins
fi

# Install AWS CLI v2 (non-interactive). Use --update if already installed.
if ! command -v aws >/dev/null 2>&1; then
	curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
	unzip -o /tmp/awscliv2.zip -d /tmp
	/tmp/aws/install --update || /tmp/aws/install || true
fi

# Create folders for artifacts and set ownership
mkdir -p /opt/app/frontend /opt/app/backend /opt/app/database /opt/jenkins_home
chown -R ec2-user:ec2-user /opt/app /opt/jenkins_home || true

echo "jenkins_user_data: installation complete"
