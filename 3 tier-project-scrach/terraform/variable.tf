variable "region" { default = "ap-south-1" }

# variable "public_key_path" {
#   description = "Path to public key for EC2"
#   default     = "~/Downloads/"
# }
variable "key_name" {
  description = "Existing EC2 keypair name"
  default     = "Demo-project-key"
}
variable "jenkins_instance_type" { default = "t3.micro" }
variable "app_instance_type" { default = "c7i-flex.large" }
variable "nexus_instance_type" { default = "c7i-flex.large" }
variable "db_username" { default = "demo" }
variable "db_password" { default = "Dem0Passw0rd!" }
variable "db_name" { default = "demo_db" }
variable "public_key" {
  description = "Public key material for EC2 key pair. Provide the public key contents (not a path)."
  default     = ""
}