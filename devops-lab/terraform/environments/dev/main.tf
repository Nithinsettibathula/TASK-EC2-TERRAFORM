provider "aws" {
  region = "eu-north-1"   
}

# --- AUTOMATIC AMI LOOKUP ---
# This block asks AWS: "Give me the latest Ubuntu 22.04 ID for this region"
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Official Ubuntu Publisher)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "vpc" {
  source             = "../../modules/vpc"
  env                = "dev"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
  az                 = "eu-north-1a"  
}

module "compute" {
  source        = "../../modules/ec2"
  env           = "dev"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_id
  
  # Stockholm (eu-north-1) uses T3 instances for free tier usually
  instance_type = "t3.micro"       
  
  # Use the ID we found automatically above
  ami_id        = data.aws_ami.ubuntu.id 
  
  key_name      = var.key_name
}