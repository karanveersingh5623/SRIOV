provider "libvirt" {
  uri = "qemu:///system"
  #uri = "qemu+ssh://root@195.167.137.76/system"
}

variable "vm_machines" {
  description = "Create machines with these names"
  type = list(string)
  default = ["worker01", "worker02", "worker03", "worker04","worker05", "worker06", "worker07", "worker08"]
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "ubuntu" {
  name = "${var.vm_machines[count.index]}.qcow2"
  count = length(var.vm_machines)
  pool = "default"
  source = "/var/lib/libvirt/images/packer-qemu"
  format = "qcow2"
}


# Use CloudInit to add our ssh-key to the instance
resource "libvirt_cloudinit_disk" "commoninit" {
          name = "commoninit.iso"
          pool = "default"
          user_data = "${data.template_file.user_data.rendered}"
          network_config = "${data.template_file.network_config.rendered}"
        }

data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.cfg")}"
}

data "template_file" "network_config" {
  template = "${file("${path.module}/network_config.cfg")}"
}


# Create the machine
resource "libvirt_domain" "ubuntu" {
  count = length(var.vm_machines)
  name = var.vm_machines[count.index]
  memory = "8196"
  vcpu = 2

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"
  
  # uses DHCP
  network_interface {
       network_name = "default"
  }

  # IMPORTANT
  # Ubuntu can hang is a isa-serial is not present at boot time.
  # If you find your CPU 100% and never is available this is why
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
      type        = "pty"
      target_type = "virtio"
      target_port = "1"
  }

  disk {
       volume_id = libvirt_volume.ubuntu[count.index].id
  }
  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }
}
