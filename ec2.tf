# 3. Updated Security Group to allow Internal SSH between Control & Targets
resource "aws_security_group" "ansible_sg" {
  name        = "ansible-core-sg"
  description = "Internal SSH and full outbound access"
  vpc_id      = aws_vpc.mirror_vpc.id 

  # Allow SSH ONLY from within this same Security Group (Internal traffic)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    self            = true
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true
  }
  
  # Allow ALL Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 5. IAM Roles and Profiles (Kept for SSM capability)
resource "aws_iam_role" "ssm_role" {
  name = "ansible-core-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Keep your existing SSM Policy Attachment
resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# NEW: Add a policy specifically allowing the Control Node to look up EC2 targets
resource "aws_iam_role_policy" "ec2_describe_policy" {
  name = "ansible-control-ec2-describe"
  role = aws_iam_role.ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:DescribeInstances"]
      Resource = "*" # Describe operations do not support resource-level permissions
    }]
  })
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ansible-core-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

# Fetch latest RHEL 9 AMI
data "aws_ami" "rhel_latest" {
  most_recent = true
  owners      = ["309956199498"] # Official Red Hat Owner ID

  filter {
    name   = "name"
    values = ["RHEL-9*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ==========================================
# 6. INSTANCE 1: Ansible Control Server
# ==========================================
resource "aws_instance" "control_server" {
  ami           = data.aws_ami.rhel_latest.id
  instance_type = "t3.large"

  root_block_device {
    volume_size           = 30 # Slightly increased for tools/dependencies
    volume_type           = "gp3"
    delete_on_termination = true 
  }
  
  subnet_id                   = aws_subnet.public_subnet.id 
  vpc_security_group_ids      = [aws_security_group.ansible_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name

  # Inline User Data script to install Ansible Core + Crypto Collection
  user_data = file("${path.module}/scripts/control_init.sh")

  tags = { Name = "ansible-control-server" }
}

# ==========================================
# 7. INSTANCE 2 & 3: Target Managed Nodes
# ==========================================
resource "aws_instance" "target_nodes" {
  count         = 2
  ami           = data.aws_ami.rhel_latest.id
  instance_type = "t3.medium"

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true 
  }
  
  subnet_id                   = aws_subnet.public_subnet.id 
  vpc_security_group_ids      = [aws_security_group.ansible_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name

  # Targets only require python3 to be managed by Ansible
  user_data = file("${path.module}/scripts/target_init.sh")

  tags = { 
    Name = "ansible-target-node-${count.index + 1}" 
  }
}