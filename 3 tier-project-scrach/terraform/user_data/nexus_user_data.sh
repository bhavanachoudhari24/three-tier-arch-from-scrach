#!/bin/bash
yum update -y
amazon-linux-extras install java-openjdk17 -y
yum install -y docker
service docker start
usermod -a -G docker ec2-user
# run Nexus OSS
docker run -d --name nexus -p 8081:8081 -v /nexus-data:/nexus-data sonatype/nexus3
