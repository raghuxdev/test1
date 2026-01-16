# Base version - This should be committed to main branch first
# This file uses t2.micro instance type

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.large"  # ❌ UPSIZE: t2.micro -> t2.medium (WILL FAIL)

  tags = {
    Name = "web-server"
  }
}

resource "aws_launch_template" "api" {
  name_prefix   = "api-server-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.small"  # ❌ UPSIZE: t2.small -> t2.large (WILL FAIL)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "api-server"
    }
  }
}

resource "aws_autoscaling_group" "workers" {
  name                = "worker-asg"
  vpc_zone_identifier = ["subnet-12345"]
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.workers_lt.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "workers_lt" {
  name_prefix   = "workers-lt-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.small"  # ❌ UPSIZE: t3.micro -> t3.small (WILL FAIL)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "worker-instance"
    }
  }
}

# ============================================
# GCP Resources
# ============================================

resource "google_compute_instance" "app_server" {
  name         = "app-server"
  machine_type = "e2-medium"  # ❌ UPSIZE: e2-micro -> e2-medium (WILL FAIL)
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }
}

resource "google_compute_instance" "db_server" {
  name         = "db-server"
  machine_type = "n1-standard-4"  # ❌ UPSIZE: n1-standard-1 -> n1-standard-4 (WILL FAIL)
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }
}

resource "google_compute_instance_template" "worker_template" {
  name_prefix  = "worker-template-"
  machine_type = "e2-standard-2"  # ❌ UPSIZE: e2-small -> e2-standard-2 (WILL FAIL)

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
  }
}

# ============================================
# Azure Resources
# ============================================

resource "azurerm_linux_virtual_machine" "web_vm" {
  name                = "web-vm"
  resource_group_name = "my-resource-group"
  location            = "East US"
  size                = "Standard_M416ms_v2"  # ❌ UPSIZE: Standard_B1s -> Standard_D2s_v3 (WILL FAIL)
  admin_username      = "adminuser"

  network_interface_ids = [
    "nic-id-placeholder"
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "api_vm" {
  name                = "api-vm"
  resource_group_name = "my-resource-group"
  location            = "East US"
  size                = "Standard_D4s_v3"  # ❌ UPSIZE: Standard_B2s -> Standard_D4s_v3 (WILL FAIL)
  admin_username      = "adminuser"

  network_interface_ids = [
    "nic-id-placeholder"
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "worker_vmss" {
  name                = "worker-vmss"
  resource_group_name = "my-resource-group"
  location            = "East US"
  sku                 = "Standard_D2s_v3"  # ❌ UPSIZE: Standard_B1ms -> Standard_D2s_v3 (WILL FAIL)
  instances           = 2
  admin_username      = "adminuser"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "worker-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = "subnet-id-placeholder"
    }
  }
}
