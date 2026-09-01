# Arista AVD + Containerlab Lab

This lab provides a six-node Arista cEOS fabric for development and testing with Arista Validated Designs (AVD).

## Topology

The initial fabric consists of:

* 2 spines
* 4 leaves
* 2 MLAG leaf pairs
* Arista cEOS 4.36.2F
* Containerlab
* Arista AVD 6.4.0

```text
                 spine1             spine2
                /  |  \           /  |  \
               /   |   \         /   |   \
            leaf1 leaf2       leaf3 leaf4
              ║     ║           ║     ║
              ╚═════╝           ╚═════╝
                MLAG              MLAG
```

Management addressing:

| Device | Management IP |
| ------ | ------------- |
| spine1 | 172.20.20.11  |
| spine2 | 172.20.20.12  |
| leaf1  | 172.20.20.21  |
| leaf2  | 172.20.20.22  |
| leaf3  | 172.20.20.23  |
| leaf4  | 172.20.20.24  |

Management network:

```text
172.20.20.0/24
```

---

# Host Requirements

The current lab host uses:

```text
Ubuntu 24.04.1 LTS
x86_64 / amd64
16 GB RAM
```

Recommended minimum:

* 4+ CPU cores
* 16 GB RAM
* 30+ GB free disk space
* Hardware virtualization where applicable

Verify the architecture:

```bash
uname -m
```

Expected:

```text
x86_64
```

---

# Install Docker and Containerlab

Containerlab provides an installer capable of installing Docker CE, Docker Compose, Containerlab, and supporting utilities.

Before running the installer, disable its optional SSH daemon modifications:

```bash
export SETUP_SSHD="false"
```

Run the Containerlab `all` installation procedure from the official Containerlab installation documentation.

After installation, either log out and log back in or refresh Docker group membership:

```bash
newgrp docker
```

For a normal SSH environment, logging out and reconnecting is preferred because it refreshes all supplementary group memberships.

Verify Docker:

```bash
docker version
```

The lab was initially built with:

```text
Docker Engine 27.5.1
Docker API 1.47
```

Containerlab 0.79.0 requires Docker functionality newer than API 1.43, so the Docker server API should be at least 1.44.

Verify Containerlab:

```bash
containerlab version
```

The initial lab used:

```text
Containerlab 0.79.0
```

Verify group membership:

```bash
groups
```

The user should have access to:

```text
docker
clab_admins
```

Check whether the Containerlab administrative group exists:

```bash
getent group clab_admins
```

If necessary, add the current user:

```bash
sudo usermod -aG clab_admins $USER
```

Then log out and log back in.

Verify the Containerlab executable:

```bash
ls -l "$(which containerlab)"
```

A sudo-less Containerlab installation may show the SUID bit:

```text
-rwsr-xr-x
```

Test Docker:

```bash
docker run --rm hello-world
```

---

# Install Arista cEOS

Download the desired `cEOS-lab` image through the Arista software portal.

This lab uses:

```text
cEOS-lab-4.36.2F.tar.xz
```

Copy the image archive to the Linux lab server.

Import it into Docker:

```bash
docker import cEOS-lab-4.36.2F.tar.xz ceos:4.36.2F
```

Verify:

```bash
docker images | grep ceos
```

Expected:

```text
ceos    4.36.2F
```

---

# Create the Lab Directory

Create the project directory:

```bash
mkdir -p ~/avd/lab1
cd ~/avd/lab1
```

The Containerlab topology file is:

```text
lab1.clab.yml
```

---

# Containerlab Topology

Create the file:

```bash
vi ~/avd/lab1/lab1.clab.yml
```

Add:

```yaml
name: lab1

mgmt:
  network: avd_mgmt
  ipv4-subnet: 172.20.20.0/24

topology:
  kinds:
    arista_ceos:
      image: ceos:4.36.2F
      env:
        CLAB_MGMT_VRF: MGMT

  nodes:
    spine1:
      kind: arista_ceos
      mgmt-ipv4: 172.20.20.11

    spine2:
      kind: arista_ceos
      mgmt-ipv4: 172.20.20.12

    leaf1:
      kind: arista_ceos
      mgmt-ipv4: 172.20.20.21

    leaf2:
      kind: arista_ceos
      mgmt-ipv4: 172.20.20.22

    leaf3:
      kind: arista_ceos
      mgmt-ipv4: 172.20.20.23

    leaf4:
      kind: arista_ceos
      mgmt-ipv4: 172.20.20.24

  links:
    # Leaf1 uplinks
    - endpoints: ["spine1:eth1", "leaf1:eth1"]
    - endpoints: ["spine2:eth1", "leaf1:eth2"]

    # Leaf2 uplinks
    - endpoints: ["spine1:eth2", "leaf2:eth1"]
    - endpoints: ["spine2:eth2", "leaf2:eth2"]

    # Leaf3 uplinks
    - endpoints: ["spine1:eth3", "leaf3:eth1"]
    - endpoints: ["spine2:eth3", "leaf3:eth2"]

    # Leaf4 uplinks
    - endpoints: ["spine1:eth4", "leaf4:eth1"]
    - endpoints: ["spine2:eth4", "leaf4:eth2"]

    # MLAG leaf1/leaf2
    - endpoints: ["leaf1:eth3", "leaf2:eth3"]
    - endpoints: ["leaf1:eth4", "leaf2:eth4"]

    # MLAG leaf3/leaf4
    - endpoints: ["leaf3:eth3", "leaf4:eth3"]
    - endpoints: ["leaf3:eth4", "leaf4:eth4"]
```

The resulting interface layout is:

| Device | Ethernet1 | Ethernet2 | Ethernet3 | Ethernet4 |
| ------ | --------- | --------- | --------- | --------- |
| spine1 | leaf1     | leaf2     | leaf3     | leaf4     |
| spine2 | leaf1     | leaf2     | leaf3     | leaf4     |
| leaf1  | spine1    | spine2    | leaf2     | leaf2     |
| leaf2  | spine1    | spine2    | leaf1     | leaf1     |
| leaf3  | spine1    | spine2    | leaf4     | leaf4     |
| leaf4  | spine1    | spine2    | leaf3     | leaf3     |

Containerlab uses `eth0` for cEOS management. Data interfaces beginning with `eth1` correspond to the EOS Ethernet interfaces used by the topology.

---

# Deploy the Lab

From the project directory:

```bash
cd ~/avd/lab1
```

Deploy:

```bash
clab deploy -t lab1.clab.yml
```

Inspect the lab:

```bash
clab inspect -t lab1.clab.yml
```

The containers should be named:

```text
clab-lab1-spine1
clab-lab1-spine2
clab-lab1-leaf1
clab-lab1-leaf2
clab-lab1-leaf3
clab-lab1-leaf4
```

Check Docker:

```bash
docker ps
```

Monitor resource utilization:

```bash
docker stats
```

---

# Access cEOS

Open the EOS CLI on a device:

```bash
docker exec -it clab-lab1-spine1 Cli
```

Example verification commands:

```text
show version
show interfaces status
show ip interface brief
show vrf
show ip interface brief vrf MGMT
```

Containerlab initially configures the cEOS management environment so the devices can be managed before AVD configuration is deployed.

---

# Destroy the Lab

Destroy the topology while retaining generated lab files:

```bash
clab destroy -t lab1.clab.yml
```

Destroy the topology and clean generated Containerlab artifacts:

```bash
clab destroy -t lab1.clab.yml --cleanup
```

Recreate it:

```bash
clab deploy -t lab1.clab.yml
```

---

# VS Code

The development workflow is:

```text
Windows Workstation
        |
        | SSH
        v
Ubuntu Lab VM
        |
        +-- Docker
        |
        +-- Containerlab
        |     |
        |     +-- spine1
        |     +-- spine2
        |     +-- leaf1
        |     +-- leaf2
        |     +-- leaf3
        |     +-- leaf4
        |
        +-- AVD Dev Container
```

Use the Microsoft extensions:

```text
Remote - SSH
Dev Containers
```

Connect to the Ubuntu VM using Remote SSH and open:

```text
/home/<user>/avd/lab1
```

---

# Arista AVD Development Container

The lab uses Arista Validated Designs 6.4.0.

Create:

```text
~/avd/lab1/.devcontainer/devcontainer.json
```

Example:

```json
{
    "name": "AVD Universal",
    "image": "ghcr.io/aristanetworks/avd/universal:python3.11-avd-v6.4.0",

    "runArgs": [
        "--network=avd_mgmt"
    ],

    "customizations": {
        "vscode": {
            "extensions": [
                "redhat.ansible",
                "redhat.vscode-yaml",
                "ms-python.python"
            ]
        }
    }
}
```

The AVD devcontainer is attached to:

```text
avd_mgmt
```

This allows Ansible inside the AVD container to communicate directly with the cEOS management addresses.

In VS Code, use:

```text
Dev Containers: Rebuild and Reopen in Container
```

Verify the AVD environment:

```bash
whoami
pwd
python --version
ansible --version
ansible-galaxy collection list | grep arista
```

Expected AVD collection:

```text
arista.avd    6.4.0
```

---

# Planned Repository Layout

```text
~/avd/lab1/
├── README.md
├── lab1.clab.yml
├── .devcontainer/
│   └── devcontainer.json
├── ansible.cfg
├── inventory.yml
├── build.yml
├── deploy.yml
├── group_vars/
│   ├── FABRIC.yml
│   ├── DC1.yml
│   ├── DC1_SPINES.yml
│   └── DC1_L3_LEAVES.yml
├── intended/
└── documentation/
```

AVD will be responsible for generating and deploying the EOS fabric configuration. Containerlab is responsible for creating and wiring the virtual cEOS nodes.

The initial AVD design will use:

```text
Underlay:       eBGP
Overlay:        eBGP EVPN
VXLAN:          Leaf VTEPs
Spines:         2
Leaves:         4
MLAG pairs:     leaf1/leaf2 and leaf3/leaf4
Spine ASN:      65000
Leaf pair ASN:  65101 and 65102
```
