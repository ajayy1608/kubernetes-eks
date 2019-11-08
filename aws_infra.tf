provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "test-vpc" {
  cidr_block = "192.168.0.0/16"
}

resource "aws_subnet" "web" {
  vpc_id     = aws_vpc.test-vpc.id
  cidr_block = "192.168.0.0/20"
  tags = {
    Name = "web"
    "kubernetes.io/cluster/cluster-k8" = "shared"
  }
}

resource "aws_subnet" "app-1" {
  vpc_id            = aws_vpc.test-vpc.id
  cidr_block        = "192.168.16.0/20"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "app-1"
    "kubernetes.io/cluster/cluster-k8" = "shared"
  }
}

resource "aws_subnet" "app-2" {
  vpc_id            = aws_vpc.test-vpc.id
  cidr_block        = "192.168.32.0/20"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "app-2",
    "kubernetes.io/cluster/cluster-k8" = "shared"
  }
}

resource "aws_internet_gateway" "test-igw" {
  vpc_id = aws_vpc.test-vpc.id
}

resource "aws_eip" "nat" {
  vpc      = true

  depends_on = ["aws_internet_gateway.test-igw"]
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.web.id

  depends_on = ["aws_internet_gateway.test-igw"]
}

resource "aws_route_table" "pub-rt" {
  vpc_id = "${aws_vpc.test-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.test-igw.id}"
  }
}

resource "aws_route_table_association" "rt-association" {
  subnet_id      = "${aws_subnet.web.id}"
  route_table_id = "${aws_route_table.pub-rt.id}"
}

resource "aws_route_table" "pvt-rt" {
  vpc_id = "${aws_vpc.test-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.ngw.id}"
  }
}

resource "aws_route_table_association" "app-1-rt-association" {
  subnet_id      = "${aws_subnet.app-1.id}"
  route_table_id = "${aws_route_table.pvt-rt.id}"
}

resource "aws_route_table_association" "app-2-rt-association" {
  subnet_id      = "${aws_subnet.app-2.id}"
  route_table_id = "${aws_route_table.pvt-rt.id}"
}

resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "SG for web"
  vpc_id      = aws_vpc.test-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_key_pair" "test-key" {
  key_name   = "test-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDb/Q5PyXmvd2Zz8FGLIp69VguZZJHsubdluoqafxdhclvLQWalGQWBws2Li3gZrgznyv2l99R/Ou3Kj59BULhd8u4hlgn9rVMO8QBZAxvUmfDLJuMvJHrMBkuC8fw+F/L3GFjnBV6i13BG4G9yNjTG45De8FnrBdmj0hf3TpW3dpUECCemMSPOwEoxDM9gG90pVthfyseFsp5+aKFg1A2WdXb5mCX/Vanfn8Zq2tnoaNJL3PlV0XwDeYTO1Cv4PIT/296TrE0sBoDcKhxh8AueDA3cK6rA/1AseFizTC9IJxCgA1NNdqfsYKr4iWqY2gHQR8TKOV0zMohh+2AHy3iB"
}

resource "aws_instance" "bastion" {
  ami                         = "ami-02913db388613c3e1"
  instance_type               = "t3.large"
  subnet_id                   = aws_subnet.web.id
  vpc_security_group_ids      = [aws_security_group.web-sg.id]
  key_name                    = aws_key_pair.test-key.key_name
  associate_public_ip_address = true
}

