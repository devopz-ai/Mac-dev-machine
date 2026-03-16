# Virtualization Guide

Tools for running virtual machines, containers, and multi-OS environments.

## Tool Stack

| Tool | Type | Best For |
|------|------|----------|
| VirtualBox | VM | Cross-platform, Intel Macs |
| UTM | VM | Apple Silicon, ARM64 VMs |
| Vagrant | VM Management | Reproducible environments |
| Multipass | VM | Quick Ubuntu VMs |
| Lima | VM | Linux on Mac (Docker alt) |
| Colima | Container Runtime | Docker Desktop alternative |
| Podman | Container | Rootless containers |
| Docker | Container | Standard containers |

---

## VirtualBox

### Basic Usage

```bash
# List VMs
VBoxManage list vms

# Start VM
VBoxManage startvm "Ubuntu" --type headless

# Stop VM
VBoxManage controlvm "Ubuntu" poweroff

# GUI
open -a VirtualBox
```

### Create VM via CLI

```bash
# Create VM
VBoxManage createvm --name "Ubuntu" --ostype Ubuntu_64 --register

# Configure
VBoxManage modifyvm "Ubuntu" --memory 4096 --cpus 2
VBoxManage modifyvm "Ubuntu" --nic1 nat

# Create disk
VBoxManage createhd --filename ~/VMs/Ubuntu.vdi --size 20000

# Attach disk
VBoxManage storagectl "Ubuntu" --name "SATA" --add sata
VBoxManage storageattach "Ubuntu" --storagectl "SATA" --port 0 --device 0 --type hdd --medium ~/VMs/Ubuntu.vdi
```

---

## UTM (Apple Silicon)

### Overview

- **Native**: Runs ARM64 VMs at near-native speed
- **Emulation**: Can emulate x86 (slower)
- **QEMU-based**: Powerful backend

```bash
# Open UTM
open -a UTM
```

### Creating VMs

1. **ARM64 Linux** (fast):
   - Download ARM64 ISO (Ubuntu Server ARM64)
   - Create VM → Virtualize → Linux
   - Attach ISO → Start

2. **x86 Windows/Linux** (slow, emulated):
   - Create VM → Emulate → x86
   - Expect 5-10x slower than native

### Best Practices

| Guest OS | Mode | Performance |
|----------|------|-------------|
| Ubuntu ARM64 | Virtualize | Native speed |
| Fedora ARM64 | Virtualize | Native speed |
| Windows ARM64 | Virtualize | Good |
| Windows x64 | Emulate | Slow |
| Ubuntu x64 | Emulate | Slow |

---

## Vagrant

### Quick Start

```bash
# Initialize with Ubuntu
vagrant init ubuntu/jammy64
# Creates Vagrantfile

# Start VM
vagrant up

# SSH into VM
vagrant ssh

# Stop VM
vagrant halt

# Destroy VM
vagrant destroy
```

### Vagrantfile Examples

**Basic Ubuntu:**
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end
end
```

**Multi-Machine:**
```ruby
Vagrant.configure("2") do |config|
  config.vm.define "web" do |web|
    web.vm.box = "ubuntu/jammy64"
    web.vm.network "private_network", ip: "192.168.50.10"
  end

  config.vm.define "db" do |db|
    db.vm.box = "ubuntu/jammy64"
    db.vm.network "private_network", ip: "192.168.50.11"
  end
end
```

### Common Commands

```bash
vagrant up              # Start
vagrant ssh             # Connect
vagrant halt            # Stop
vagrant destroy         # Delete
vagrant reload          # Restart
vagrant provision       # Run provisioner
vagrant status          # Check status
vagrant global-status   # All VMs
```

### Provisioning

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y nginx
  SHELL
end
```

---

## Multipass

### Quick Ubuntu VMs

```bash
# Launch default Ubuntu
multipass launch --name dev

# Launch specific version
multipass launch 22.04 --name ubuntu22

# With resources
multipass launch --name dev --cpus 2 --memory 4G --disk 20G

# List VMs
multipass list

# Shell access
multipass shell dev

# Stop/Start
multipass stop dev
multipass start dev

# Delete
multipass delete dev
multipass purge  # Permanently remove
```

### Cloud-Init

```bash
# With cloud-init config
multipass launch --name dev --cloud-init config.yaml
```

```yaml
# config.yaml
packages:
  - nginx
  - git

runcmd:
  - systemctl start nginx
```

---

## Lima (Docker Alternative)

### Setup

```bash
# Install
brew install lima

# Create default VM
limactl start

# Shell access
lima

# Or run commands
lima uname -a
```

### With Docker

```bash
# Start with Docker template
limactl start --name=docker template://docker

# Set Docker context
export DOCKER_HOST=unix://$HOME/.lima/docker/sock/docker.sock

# Use Docker commands
docker run hello-world
```

---

## Colima

### Docker Desktop Alternative

```bash
# Start (creates VM + Docker)
colima start

# With resources
colima start --cpu 4 --memory 8 --disk 50

# With Kubernetes
colima start --kubernetes

# Status
colima status

# Stop
colima stop

# Use Docker normally
docker ps
docker-compose up
```

---

## Podman

### Rootless Containers

```bash
# Initialize machine (macOS)
podman machine init
podman machine start

# Same as Docker commands
podman run -it alpine sh
podman build -t myapp .
podman ps
podman images

# Docker Compose equivalent
podman-compose up
```

---

## Use Case Decision Tree

```
Need a VM?
├── Apple Silicon (M1/M2/M3/M4)?
│   ├── ARM64 guest → UTM (fast)
│   └── x86 guest → UTM emulation (slow) or cloud VM
├── Intel Mac?
│   └── VirtualBox or UTM
└── Quick Ubuntu only?
    └── Multipass

Need Containers?
├── Docker Desktop alternative?
│   ├── Colima (easiest)
│   └── Lima + Docker
└── Rootless?
    └── Podman

Need Reproducible VMs?
└── Vagrant + VirtualBox/UTM
```

---

## Performance Tips

| Tip | Description |
|-----|-------------|
| Use ARM64 guests | Native speed on Apple Silicon |
| Allocate enough RAM | 4GB+ for most Linux distros |
| SSD storage | Faster disk I/O |
| Limit CPU | Leave cores for host |
| Use snapshots | Quick restore points |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| VirtualBox slow on M1 | Use UTM instead |
| Vagrant can't find VirtualBox | Install VirtualBox Extension Pack |
| Multipass launch stuck | `multipass delete --purge` and retry |
| Colima won't start | `colima delete` and retry |
| Lima socket error | Check `limactl list`, restart |
| Permission denied | Check VM user, sudo access |
