output "jenkins_public_ip" { value = aws_instance.jenkins.public_ip }
output "nexus_public_ip" { value = aws_instance.nexus.public_ip }
output "app_public_ip" { value = aws_instance.app.public_ip }
output "s3_frontend_bucket" { value = aws_s3_bucket.frontend_bucket.bucket }
output "rds_endpoint" { value = aws_db_instance.postgres.address }