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

source "amazon-ebs" "rhel_9_3" {
  region = var.aws_region
  
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "RHEL-9.3*_HVM-*x86_64*GP3"
      root-device-type    = "ebs"
    }
    owners      = ["309956199498"]
    most_recent = true
  }

  instance_type = "t3.medium"
  ami_name    = "rhel_9_cis1_base_{{timestamp}}"
  ami_regions = [var.aws_region]

  ssh_username = "ec2-user"
  ssh_agent_auth = false
}

build {
  hcp_packer_registry {
    bucket_name = "${var.hcp_packer_bucket_base_name}-rhel-cis1-srv"
    description = "RHEL9 Base Image with CIS Level 1 Server"

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
      "sudo dnf update -y",
      "sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm",
      "sudo systemctl enable amazon-ssm-agent",
      "sudo dnf install -y scap-security-guide",
      "sudo mkdir -p /var/lib/usg/",
      "sudo oscap xccdf eval --remediate --profile xccdf_org.ssgproject.content_profile_cis_server_l1 --results /var/lib/usg/scan-xccdf-results.xml /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml || if [ $? = 2 ]; then exit 0; else exit 1; fi"
    ]
  }

  // Additional base configuration
  // provisioner "ansible" {
  //   playbook_file = "./ansible/rhel-base/playbook.yml"
  //   galaxy_file = "./ansible/rhel-base/requirements.yml"
  // }

  sources = [
    "source.amazon-ebs.rhel_9_3",
  ]
}