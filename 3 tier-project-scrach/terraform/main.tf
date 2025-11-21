
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "3tier-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.main.id }

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Security group for Jenkins & Nexus (allow HTTP, SSH)
resource "aws_security_group" "jenkins_nexus_sg" {
  name   = "jenkins-nexus-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } # Jenkins
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } # Nexus default 8081
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for App EC2 (Tomcat) - allow SSH and HTTP 8080
resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for RDS (allow Postgres from app & jenkins)
resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id, aws_security_group.jenkins_nexus_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Key pair - assumes you created a key pair and uploaded the public key
# resource "aws_key_pair" "deployer" {
#   count      = var.public_key != "" ? 1 : 0
#   key_name   = var.key_name
#   public_key = var.public_key
# }

# S3 bucket for frontend
resource "aws_s3_bucket" "frontend_bucket" {
  bucket        = lower("3tier-frontend-demo21nov-${random_id.bucket_id.hex}")
  force_destroy = true
}

// Note: public ACLs are blocked in this AWS account (BlockPublicAcls).
// Removing the `aws_s3_bucket_acl` resource to avoid AccessDenied errors.
// If you need the bucket to serve a public website, consider one of the options:
// - Provide `public_key` and configure CloudFront with an OAI to serve private buckets
// - Use a bucket policy to grant public GetObject (if BlockPublicPolicy is not enabled)
// - Ask your AWS admin to relax Block Public Access settings for this account/bucket

resource "random_id" "bucket_id" { byte_length = 3 }

# RDS Postgres (simple, single AZ for POC)
resource "aws_db_subnet_group" "db_subnets" {
  name       = "db-subnets"
  subnet_ids = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]
}

resource "aws_db_instance" "postgres" {
  identifier             = "demo-postgres"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  allocated_storage      = 20
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  publicly_accessible    = false
}

# EC2 Instances
resource "aws_instance" "jenkins" {
  ami             = data.aws_ami.amazon_linux2.id
  instance_type   = var.jenkins_instance_type
  subnet_id       = aws_subnet.public_subnet.id
    key_name        = var.key_name
  security_groups = [aws_security_group.jenkins_nexus_sg.id]
  user_data       = file("${path.module}/user_data/jenkins_user_data.sh")
  tags            = { Name = "jenkins-server" }
}

resource "aws_instance" "nexus" {
  ami             = data.aws_ami.amazon_linux2.id
  instance_type   = var.nexus_instance_type
  subnet_id       = aws_subnet.public_subnet.id
    key_name        = var.key_name
  security_groups = [aws_security_group.jenkins_nexus_sg.id]
  user_data       = file("${path.module}/user_data/nexus_user_data.sh")
  tags            = { Name = "nexus-server" }
}

resource "aws_instance" "app" {
  ami             = data.aws_ami.amazon_linux2.id
  instance_type   = var.app_instance_type
  subnet_id       = aws_subnet.public_subnet.id
    key_name        = var.key_name
  security_groups = [aws_security_group.app_sg.id]
  user_data       = file("${path.module}/user_data/app_user_data.sh")
  tags            = { Name = "app-server" }
}

resource "aws_s3_bucket_website_configuration" "frontend_bucket_website" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}


