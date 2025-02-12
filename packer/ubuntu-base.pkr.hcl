variable "aws_region" {
  type = string
}

variable "hcp_packer_bucket_base_name" {
  type = string
}

variable "packer_image_owner" {
  type = string
}

packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu_lts" {
  region = var.aws_region
  
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu*22.04*amd64*pro-*"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"]
    most_recent = true
  }

  instance_type = "t3.medium"
  ami_name    = "ubuntu_2204_cis1_base_{{timestamp}}"
  ami_regions = [var.aws_region]

  ssh_username = "ubuntu"
  ssh_agent_auth = false
}

build {
  hcp_packer_registry {
    bucket_name = "${var.hcp_packer_bucket_base_name}-ubuntu-2204-cis1-srv"
    description = "Ubuntu 22.04 Base Image with CIS Level 1 Server"

    bucket_labels = {
      "creator" = "packer-github-actions-aws",
      "owner" = var.packer_image_owner
    }
    build_labels = {
      "build-time"   = timestamp()
      "build-source" = basename(path.cwd)
    }
  }

  // CIS Level 1 Server
  provisioner "shell" {
    inline = [
      "sleep 30",
      "sudo apt-get -o DPkg::Lock::Timeout=300 update -y",
      "sudo add-apt-repository universe",
      "sudo apt-get -o DPkg::Lock::Timeout=300 upgrade -y",
      "sudo apt-get -o DPkg::Lock::Timeout=300 install -y ubuntu-advantage-tools",
      "sudo ua enable usg",
      "sudo apt-get -o DPkg::Lock::Timeout=300 install -y usg",
      "sudo usg fix cis_level1_server",
    ]
  }

  // Additional base configuration
  // provisioner "ansible" {
  //   playbook_file = "./ansible/ubuntu-base/playbook.yml"
  //   galaxy_file = "./ansible/ubuntu-base/requirements.yml"
  // }

  sources = [
    "source.amazon-ebs.ubuntu_lts",
  ]
}