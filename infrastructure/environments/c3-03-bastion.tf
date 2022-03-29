/******************************************************************************
* Bastion Host
*******************************************************************************/
/**
* A security group to allow SSH access into our bastion instance.
*/
resource "aws_security_group" "bastion" {
  name = "bastion-security-group-"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    protocol = -1
    from_port = 0
    to_port = 0
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Resource = "modules.availability_zone.aws_security_group.bastion"
  }

}

/**
* The public key for the key pair we'll use to ssh into our bastion instance.
*/
resource "aws_key_pair" "bastion" {
  key_name = "ceros-ski-bastion-key-us-east-1a"
  public_key = file(var.public_key_path) 
}

/**
* This parameter contains the AMI ID for the most recent Amazon Linux 2 ami,
* managed by AWS.
*/
data "aws_ssm_parameter" "linux2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-ebs"
}

/**
* Launch a bastion instance we can use to gain access to the private subnets of
* this availabilty zone.
*/
resource "aws_instance" "bastion" {
  ami = data.aws_ssm_parameter.linux2_ami.value
  key_name = aws_key_pair.bastion.key_name 
  instance_type = "t3.micro"

  associate_public_ip_address = true
  subnet_id      = module.vpc.public_subnets[0] 

  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Name = "ceros-ski-${var.environment}-us-east-1a-bastion"
    Resource = "modules.availability_zone.aws_instance.bastion"
  }
}