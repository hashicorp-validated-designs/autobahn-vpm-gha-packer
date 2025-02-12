
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
    ansible = {
      version = ">= 1.1.1"
      source = "github.com/hashicorp/ansible"
    }
  }
}

data "hcp-packer-artifact" "ubuntu" {
  bucket_name = "${var.hcp_packer_bucket_base_name}-ubuntu-2204-cis1-srv"
  platform = "aws"
  channel_name = "latest"
  region = var.aws_region
}

source "amazon-ebs" "ubuntu_lts_mysql" {
  region = var.aws_region
  
  source_ami = data.hcp-packer-artifact.ubuntu.external_identifier

  instance_type = "t3.medium"
  ami_name    = "ubuntu_2204_cis1_mysql_{{timestamp}}"
  ami_regions = [var.aws_region]

  ssh_username = "ubuntu"
  ssh_agent_auth = false
}

build {
  hcp_packer_registry {
    bucket_name = "${var.hcp_packer_bucket_base_name}-ubuntu-2204-cis1-srv-mysql"
    description = "Ubuntu 22.04 CIS Level 1 +MYSQL"

    bucket_labels = {
      "creator" = "packer-github-actions-aws",
      "owner" = var.packer_image_owner
    }
    build_labels = {
      "build-time"   = timestamp()
      "build-source" = basename(path.cwd)
    }
  }

  provisioner "ansible" {
    playbook_file = "./ansible/mysql/playbook.yml"
    galaxy_file = "./ansible/mysql/requirements.yml"
    // extra_arguments = ["-e", "{ 
    //   \"param\": false,
    // }"]
  }

  sources = [
    "source.amazon-ebs.ubuntu_lts_mysql",
  ]
}