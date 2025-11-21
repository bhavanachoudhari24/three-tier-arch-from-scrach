#!/bin/bash
yum update -y
amazon-linux-extras install java-openjdk17 -y
# install Tomcat 9
cd /opt
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.73/bin/apache-tomcat-9.0.73.tar.gz -O tomcat.tar.gz
tar xzf tomcat.tar.gz
mv apache-tomcat-9.0.73 tomcat
chown -R ec2-user:ec2-user /opt/tomcat
mkdir -p /opt/app/backend /opt/app/frontend /opt/app/database
# create systemd service for tomcat
cat > /etc/systemd/system/tomcat.service <<'EOF'
[Unit]
Description=Apache Tomcat
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/tomcat
ExecStart=/opt/tomcat/bin/catalina.sh run
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat

# install psql client to run migrations
yum install -y postgresql
