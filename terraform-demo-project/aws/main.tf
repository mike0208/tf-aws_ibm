#------------ AWS
#-------------aws/main.tf

resource "random_integer" "random" {
  min = 1
  max = 50
}

resource "aws_vpc" "mike_vpc" {
  cidr_block           = "10.240.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "mike-vpc-${random_integer.random.id}"
  }
}

data "aws_availability_zones" "availability_zones" {
}

resource "aws_subnet" "public_subnet" {
  cidr_block              = "10.240.0.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.mike_vpc.id
  availability_zone       = data.aws_availability_zones.availability_zones.names[0]

  tags = {
    Name = "mike_public_subnet_${random_integer.random.id + 1}"
  }
}

# create an IGW (Internet Gateway)
# It enables your vpc to connect to the internet
resource "aws_internet_gateway" "public-igw" {
  vpc_id = aws_vpc.mike_vpc.id

  tags = {
    Name = "public-igw"
  }
}

# create a custom route table for public subnets
# public subnets can reach to the internet buy using this
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.mike_vpc.id
  route {
    cidr_block = "0.0.0.0/0"                        //associated subnet can reach everywhere
    gateway_id = aws_internet_gateway.public-igw.id //RT uses this IGW to reach internet
  }

  tags = {
    Name = "public-rt"
  }
}


# route table association for the public subnets
resource "aws_route_table_association" "rt-association-public-subnet" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public-rt.id
}

# security group
resource "aws_security_group" "mike_public_sg" {
  name        = "public_sg"
  description = "security group for public access on ssh"
  vpc_id      = aws_vpc.mike_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_access_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-sg-ssh-access"
  }
}

data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "instance_keypair" {
  key_name   = "instance-public-key"
  public_key = file(local.ssh_key_path)
}

resource "aws_instance" "mike_instance" {
  count         = var.instance_count #1
  instance_type = var.instance_type  #t2.micro
  ami           = data.aws_ami.server_ami.id

  subnet_id = aws_subnet.public_subnet.id

  tags = {
    Name = "mike_instance-${random_integer.random.id}"
  }
  key_name               = aws_key_pair.instance_keypair.id
  vpc_security_group_ids = [aws_security_group.mike_public_sg.id]
  #security_groups = [aws_security_group.mike_public_sg.id]

 /* provisioner "file" {
    source      = "../ibm/image_name.txt"
    destination = "/tmp/image_name.ini"
  }*/
  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/.ssh", 
      "ssh-keygen -f ~/.ssh/ssh_test -N '' -t rsa"
    ]
  }
  provisioner "local-exec"{
    command = <<DONE
      rm -rf ${local.instance_ssh_path} \
        scp -i ${local.private_key_path} -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -r "ubuntu@${self.public_ip}:~/.ssh" ${local.instance_ssh_path}
    DONE
  }
  
  connection {
    type        = "ssh"
    user        = var.ec2_user
    host        = self.public_ip
    private_key = file(local.private_key_path)
  }
}

/*resource "local_file" "public_ssh" {
  content = file("${local.instance_ssh_path}ssh_test.pub")
  filename = "${path.cwd}/ssh/instance_key.pub"
  depends_on = [aws_instance.mike_instance]
}*/


