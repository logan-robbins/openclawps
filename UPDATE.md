# OpenClawps Evolution Plan

## Premise

OpenClawps runs **full desktop VMs with real X11, real Chrome, real VNC**. Each claw is a complete workstation — the equivalent of a physical computer on a desk with a human sitting at it. The agent has unrestricted OS access: it clicks, types, opens browsers, runs terminals, manages files. There is no Docker, no Kubernetes, no container isolation. That constraint is the product. Everything in this plan operates within that constraint.

The current codebase has four lifecycle phases managed by `deploy.sh`:

| Phase | Command | What it does |
|---|---|---|
| scratch | `deploy.sh scratch` | Stock Ubuntu → full install via cloud-init (~10 min) |
| bake | `deploy.sh bake 1.0.0` | Capture running VM → Compute Gallery image |
| image | `deploy.sh` | Stamp out new claw from gallery image + fresh data disk (~2 min) |
| upgrade | `deploy.sh upgrade alice --image 2.0.0` | Detach data disk → destroy VM → new VM from new image → reattach disk |

The two-layer separation (immutable system image / portable data disk) is the core architectural insight and must be preserved through every evolution.

---

## Phase 1: Infrastructure as Code (Terraform)

**Goal:** Replace `deploy.sh`'s imperative `az` CLI calls with declarative Terraform. Make fleet state inspectable, diffable, and reviewable.

### What deploy.sh creates today (mapped to Terraform resources)

```
deploy.sh az CLI call                    → Terraform resource
─────────────────────────────────────────────────────────────
az group create                          → azurerm_resource_group
az network vnet create                   → azurerm_virtual_network + azurerm_subnet
az network nsg create + rule             → azurerm_network_security_group + azurerm_network_security_rule
az vm create                             → azurerm_linux_virtual_machine + azurerm_network_interface + azurerm_public_ip
az disk create                           → azurerm_managed_disk
(implicit via --attach-data-disks)       → azurerm_virtual_machine_data_disk_attachment
az sig create                            → azurerm_shared_image_gallery
az sig image-definition create           → azurerm_shared_image
az sig image-version create              → azurerm_shared_image_version
```

### Proposed directory structure

```text
openclawps/
├── bin/
│   └── deploy.sh                    # operator entrypoint
├── infra/
│   └── azure/
│       ├── shell/                   # current az CLI implementation
│       │   └── deploy.sh
│       ├── terraform/
│       │   ├── modules/
│       │   │   ├── shared-infra/
│       │   │   ├── image-gallery/
│       │   │   └── claw-vm/
│       │   ├── environments/
│       │   │   ├── dev/
│       │   │   └── prod/
│       │   └── versions.tf
│       └── packer/
│           ├── claw-base.pkr.hcl
│           └── scripts/
├── vm-runtime/
│   ├── cloud-init/
│   │   ├── scratch.yaml
│   │   └── image.yaml
│   ├── lifecycle/
│   │   ├── boot.sh
│   │   ├── run-updates.sh
│   │   ├── start-claude.sh
│   │   └── verify.sh
│   ├── defaults/                    # seeded onto data disk at first boot
│   └── updates/
├── fleet/
│   ├── dev/
│   └── prod/
└── apps/
    └── topology/
```

`vm-runtime/` is the shared guest payload. The shell path, future Terraform path, and future Packer path should all consume the same files from there rather than maintaining separate copies.

### The fleet manifest: `claws.yaml`

This is the single source of truth for your fleet. Terraform reads it with `yamldecode(file("claws.yaml"))` and iterates with `for_each`.

```yaml
# claws.yaml — declarative fleet definition
# Every claw in the fleet is defined here. Git diff shows exactly what changed.

defaults:
  vm_size: Standard_D2s_v3
  data_disk_size_gb: 32
  data_disk_sku: Standard_LRS
  image_version: "1.0.0"
  model: xai/grok-4.20-0309-reasoning

claws:
  alice:
    telegram_bot_token_ref: vault://secret/claws/alice#telegram_bot_token
    # Or for early stages before Vault: secrets_env_file: .env.alice
    model: xai/grok-4
    vm_size: Standard_D4s_v3  # override default

  bob:
    telegram_bot_token_ref: vault://secret/claws/bob#telegram_bot_token
    image_version: "2.0.0"   # bob runs a newer image

  carol:
    telegram_bot_token_ref: vault://secret/claws/carol#telegram_bot_token
    data_disk_size_gb: 64     # carol needs more workspace
```

### The claw-vm module (core)

```hcl
# modules/claw-vm/main.tf

resource "azurerm_public_ip" "this" {
  name                = "${var.claw_name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "this" {
  name                = "${var.claw_name}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

# Data disk exists independently of VM lifecycle.
# prevent_destroy ensures `terraform destroy` cannot accidentally delete claw state.
resource "azurerm_managed_disk" "data" {
  name                 = "${var.claw_name}-data"
  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_type = var.data_disk_sku
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = var.claw_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = "azureuser"
  admin_password                  = var.vm_password
  disable_password_authentication = false
  custom_data                     = base64encode(data.template_file.cloud_init.rendered)
  network_interface_ids           = [azurerm_network_interface.this.id]
  source_image_id                 = var.image_version_id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  security_type = "TrustedLaunch"
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  managed_disk_id    = azurerm_managed_disk.data.id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = 0
  caching            = "ReadWrite"
}
```

### What this gives you over deploy.sh

- **`terraform plan`** — see exactly what will change before it happens
- **`terraform state list`** — instant fleet inventory
- **Remote state** — multiple operators, CI/CD pipelines, no `.state/shell/current.env` file
- **`for_each` over claws.yaml** — add a claw by adding 3 lines of YAML and running `terraform apply`
- **`prevent_destroy` on data disks** — infrastructure-level protection against accidental state loss
- **Drift detection** — `terraform plan` catches manual changes

### Upgrade flow in Terraform

The `deploy.sh upgrade` flow (detach disk → destroy VM → new VM → reattach disk) maps to changing `var.image_version_id` in claws.yaml and running `terraform apply`. Terraform sees the source_image_id changed, plans a destroy/recreate of the VM resource, but the data disk (separate resource with `prevent_destroy`) survives. boot.sh handles the rest on first boot — same as today.

### deploy.sh doesn't die — it wraps Terraform

Keep deploy.sh as a thin wrapper for the common workflows:

```bash
./bin/deploy.sh plan              # terraform plan
./bin/deploy.sh apply             # terraform apply
./bin/deploy.sh add alice         # append to claws.yaml + apply
./bin/deploy.sh upgrade alice 2.0 # update image_version in claws.yaml + apply
./bin/deploy.sh ssh alice         # look up IP from terraform output, ssh in
./bin/deploy.sh vnc alice         # open vnc://IP:5900
./bin/deploy.sh status            # terraform output -json | pretty-print fleet status
```

---

## Phase 2: Golden Image Pipeline (Packer)

**Goal:** Replace `deploy.sh bake` with a repeatable, CI-triggered Packer build. Every image is built from source, not captured from a snowflake VM.

### What `deploy.sh bake` does today

1. SSH into running VM, clean up transient state
2. `waagent -deprovision+user` (generalize)
3. `az vm deallocate` → `az vm generalize`
4. `az sig image-version create` from the generalized VM

This is **capture-based**: you build a VM by hand (or via `scratch`), then snapshot it. It works but it's not reproducible — the image depends on whatever state the VM was in when you captured it.

### Packer makes it build-from-source

```hcl
# packer/claw-base.pkr.hcl

packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

source "azure-arm" "claw-base" {
  os_type                   = "Linux"
  image_publisher           = "Canonical"
  image_offer               = "ubuntu-24_04-lts"
  image_sku                 = "server"
  vm_size                   = "Standard_D2s_v3"
  managed_image_name        = "claw-base-{{timestamp}}"
  managed_image_resource_group_name = var.resource_group

  shared_image_gallery_destination {
    gallery_name        = "clawGallery"
    image_name          = "claw-base"
    image_version       = var.image_version
    resource_group      = var.resource_group
    replication_regions = ["eastus"]
  }
}

build {
  sources = ["source.azure-arm.claw-base"]

  # Install everything that vm-runtime/cloud-init/scratch.yaml currently does
  provisioner "shell" {
    scripts = [
      "scripts/01-system-packages.sh",    # apt: xfce4, x11vnc, chrome, etc.
      "scripts/02-openclaw.sh",            # npm install -g openclaw
      "scripts/03-claude-code.sh",         # claude code CLI
      "scripts/04-tailscale.sh",           # tailscale client
      "scripts/05-systemd-units.sh",       # openclaw-gateway.service, x11vnc.service, etc.
    ]
  }

  # Stage boot files
  provisioner "file" {
    source      = "../vm-runtime/lifecycle/boot.sh"
    destination = "/opt/claw/boot.sh"
  }
  provisioner "file" {
    source      = "../vm-runtime/lifecycle/run-updates.sh"
    destination = "/opt/claw/run-updates.sh"
  }
  provisioner "file" {
    source      = "../vm-runtime/defaults/"
    destination = "/opt/claw/defaults"
  }
  provisioner "file" {
    source      = "../vm-runtime/updates/"
    destination = "/opt/claw/updates"
  }
  provisioner "file" {
    source      = "../vm-runtime/lifecycle/verify.sh"
    destination = "/opt/claw/verify.sh"
  }

  # Cleanup for generalization
  provisioner "shell" {
    script = "scripts/99-cleanup.sh"  # rm -rf /tmp/*, waagent -deprovision, etc.
  }
}
```

### What changes from deploy.sh scratch → Packer

The massive `vm-runtime/cloud-init/scratch.yaml` install path gets broken into numbered shell scripts under `packer/scripts/`. Each script is independently testable. The scripts are version-controlled. Two engineers building from the same commit get identical images.

### CI/CD integration

```yaml
# .github/workflows/bake-image.yaml
name: Bake Golden Image
on:
  push:
    paths:
      - 'packer/**'
      - 'boot.sh'
      - 'defaults/**'
      - 'updates/**'
    branches: [main]

jobs:
  bake:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-packer@v3
      - run: packer init packer/
      - run: packer validate packer/
      - run: |
          VERSION=$(date +%Y.%m.%d)-$(git rev-parse --short HEAD)
          packer build -var "image_version=$VERSION" packer/
```

Every merge to main that touches the image layer automatically builds and publishes a new image version. Claws pick it up on next upgrade.

---

## Phase 3: CI/CD Pipeline (Image → Fleet)

**Goal:** Merge to main triggers: Packer build → image published → Terraform apply upgrades target claws.

### Pipeline architecture

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐     ┌──────────────┐
│ git push     │────▶│ Packer build │────▶│ Compute Gallery│────▶│ Terraform    │
│ (packer/**) │     │ (GH Actions) │     │ (new version)  │     │ apply        │
└─────────────┘     └──────────────┘     └────────────────┘     │ (upgrade     │
                                                                 │  target      │
┌─────────────┐                                                  │  claws)      │
│ git push     │────────────────────────────────────────────────▶│              │
│ (claws.yaml)│                                                  └──────┬───────┘
└─────────────┘                                                         │
                                                                        ▼
                                                              ┌──────────────────┐
                                                              │ verify.sh        │
                                                              │ (per-claw health │
                                                              │  checks via SSH) │
                                                              └──────────────────┘
```

### Rollout strategies

Because each claw is an independent VM with its own data disk, rollouts are naturally per-claw:

- **Per-claw image pinning** — `claws.yaml` specifies `image_version` per claw. Upgrade alice to 2.0.0 while bob stays on 1.0.0.
- **Canary** — upgrade one claw, run verify.sh, monitor for a day, then update the rest.
- **Blue/green per-claw** — not needed. The upgrade flow (destroy VM, recreate from new image, reattach disk) is atomic per claw. If the new image is bad, change `image_version` back and re-apply.

### Post-deploy verification

Extend `verify.sh` to run from CI:

```bash
# In the pipeline, after terraform apply:
for claw in $(yq '.claws | keys | .[]' claws.yaml); do
  ip=$(terraform output -json claw_ips | jq -r ".${claw}")
  sshpass -p "$VM_PASSWORD" ssh azureuser@$ip "sudo /opt/claw/verify.sh"
done
```

---

## Phase 4: Secrets Management

**Goal:** Get secrets out of `.env` files and into a centralized, auditable secrets store.

### Current state

Secrets flow: `.env` file on operator laptop → `envsubst` into `vm-runtime/cloud-init/image.yaml` → written to `/home/azureuser/.openclaw/.env` → `boot.sh` copies to data disk. Every secret is a plaintext string in a flat file.

### Evolution path (pick based on fleet size)

**Small fleet (< 10 claws): Azure Key Vault + Terraform data sources**

```hcl
# Each claw's secrets stored in Key Vault
data "azurerm_key_vault_secret" "telegram_token" {
  for_each     = local.claws
  name         = "${each.key}-telegram-token"
  key_vault_id = azurerm_key_vault.claws.id
}

# Passed to cloud-init via templatefile()
```

Secrets never touch Terraform state (use `sensitive = true`). Operators manage secrets via `az keyvault secret set` or the portal. Terraform reads them at apply time.

**Medium fleet (10-50 claws): HashiCorp Vault + Vault Agent**

Vault Agent runs on each VM, auto-authenticates via Azure MSI, and renders secrets to files:

```hcl
# Vault Agent template on the VM
template {
  source      = "/opt/claw/templates/env.tpl"
  destination = "/mnt/claw-data/openclaw/.env"
  perms       = 0600
}
```

Secrets are dynamic: Vault generates them on demand, leases expire, credentials rotate automatically. No `.env` files anywhere in the pipeline.

**Large fleet (50+ claws): Vault + per-claw managed identity + SPIFFE**

Each claw gets a system-assigned managed identity. Vault authenticates claws by their MSI. SPIFFE/SPIRE issues short-lived X.509 certs for inter-claw mTLS if claws need to communicate.

### Migration path

Phase 4 is independent of Phases 1-3. You can adopt Vault incrementally:

1. Start: `.env` files (current state)
2. Move API keys to Azure Key Vault, reference from Terraform
3. Deploy Vault, migrate secrets, install Vault Agent on VMs
4. Remove all static credentials from the pipeline

---

## Phase 5: Observability

**Goal:** Know what every claw is doing, how much it costs, and whether it's healthy.

### Three observability layers

```
Layer 1: VM health (is the machine running?)
├── Prometheus node_exporter on each VM
├── Custom exporter for OpenClaw-specific metrics:
│   ├── openclaw_gateway_status (up/down)
│   ├── openclaw_telegram_connected (bool)
│   ├── openclaw_x11_display_ready (bool)
│   ├── openclaw_data_disk_usage_bytes
│   └── openclaw_last_boot_timestamp
├── Azure Monitor VM insights (free tier)
└── Alerting: PagerDuty/Slack on claw-down

Layer 2: Agent behavior (what is the claw doing?)
├── Langfuse (self-hosted, MIT license)
│   ├── Trace every LLM call: model, tokens, latency, cost
│   ├── Session grouping: link traces to Telegram conversations
│   ├── Tag by claw_id for fleet-wide analytics
│   └── Prompt versioning via Langfuse Prompt CMS
├── OpenClaw transcript logs → centralized log store
│   ├── Loki + Grafana for log aggregation
│   └── Or just rsync transcripts to Azure Blob nightly
└── VNC session recording (optional, for audit)

Layer 3: Fleet economics (how much does this cost?)
├── Azure tags per claw: { claw: "alice", env: "prod", owner: "logan" }
├── Azure Cost Management + Budget alerts per tag
├── LLM spend tracking via Langfuse or LiteLLM proxy
│   ├── Per-claw token budgets with circuit breakers
│   ├── Daily/weekly cost reports
│   └── Alert on spend spikes (300%+ of baseline)
└── Composite cost: Azure VM + data disk + LLM API spend per claw
```

### Fleet dashboard

A single Grafana dashboard showing:
- Grid of claws: green/yellow/red health status
- Per-claw: uptime, last activity, token spend (24h), disk usage
- Fleet totals: total claws, total spend, claws needing upgrade
- Image version distribution: how many claws on each version

### Implementation

Langfuse self-hosts on a single small VM or Azure Container Instance (the observability infra can use containers — the claws themselves cannot). Each claw's boot.sh configures the Langfuse SDK endpoint. No code changes to OpenClaw needed if it already supports OTel or callback hooks; otherwise a thin wrapper around the LLM calls emits traces.

---

## Phase 6: Runtime Configuration (Consul KV)

**Goal:** Change claw behavior without redeploying. Hot-reloadable configuration.

### The problem

Today, changing a claw's model or Telegram policy requires either SSH + manual edit or a full VM replacement. The config lives on the data disk as static JSON files (`openclaw.json`, `.env`).

### Consul KV as the config distribution layer

```
consul kv tree:
  claws/
    _defaults/
      model: xai/grok-4.20-0309-reasoning
      max_concurrent: 4
      thinking_default: high
    alice/
      model: xai/grok-4        # override
    bob/
      model: anthropic/claude-4 # override
```

Each claw runs a lightweight Consul agent that watches its config path. On change, a watcher script regenerates `openclaw.json` from the Consul KV values and restarts the gateway service. Changes propagate in seconds, not minutes.

### Consul also gives you

- **Service discovery** — every claw registers itself, queryable via DNS (`alice.claw.service.consul`)
- **Health checks** — Consul runs verify.sh-style checks continuously, not just at deploy time
- **Prepared queries** — "give me all claws running image version < 2.0.0"

### Fleet commands via Consul events

```bash
# Pause all claws
consul event -name="fleet-pause"

# Upgrade all claws on image < 2.0.0
consul event -name="fleet-upgrade" -payload='{"target_image":"2.0.0"}'

# Restart alice's gateway
consul event -name="restart-gateway" -node="alice"
```

Each claw runs a Consul watch that listens for events and executes the appropriate handler script.

---

## Phase 7: Multi-Cloud Provider Abstraction

**Goal:** Same claw architecture on Azure, AWS, and GCP. Same claws.yaml, different cloud.

### Why this matters

The two-layer separation (system image + data disk) has direct equivalents on every cloud:

```
Concept              Azure                    AWS                     GCP
─────────────────────────────────────────────────────────────────────────────
System image         Compute Gallery          AMI                     Machine Image
Data disk            Managed Disk             EBS Volume              Persistent Disk
VM                   azurerm_linux_vm         aws_instance            google_compute_instance
Disk attach          data_disk_attachment     volume_attachment       attached_disk
Image build          Packer azure-arm         Packer amazon-ebs       Packer googlecompute
Identity             Managed Identity         IAM Instance Profile    Service Account
```

### Terraform module structure

```
terraform/modules/
  claw-vm-azure/    # azurerm_linux_virtual_machine + managed_disk
  claw-vm-aws/      # aws_instance + aws_ebs_volume
  claw-vm-gcp/      # google_compute_instance + google_compute_disk
```

Each module exposes the same interface:

```hcl
# inputs:  claw_name, vm_size, image_id, data_disk_size_gb, cloud_init, subnet_id
# outputs: public_ip, private_ip, vm_id, data_disk_id
```

The root module selects provider based on a variable:

```hcl
module "claw" {
  for_each = local.claws
  source   = "./modules/claw-vm-${var.cloud_provider}"
  # ... common variables
}
```

### Cross-cloud networking via Tailscale

Every claw joins the same tailnet at boot (already supported via `TAILSCALE_AUTHKEY` in the current codebase). Claws on Azure, AWS, and GCP can reach each other by hostname. The operator reaches any claw via `tailscale ssh alice` regardless of cloud. Consul can run over the tailnet for cross-cloud service discovery and config distribution.

### Don't abstract what doesn't need abstracting

Per-cloud modules should be cloud-native internally. Don't wrap Azure NSGs and AWS Security Groups in a generic "firewall" abstraction — they have different semantics. The abstraction boundary is the module interface (inputs/outputs), not the implementation.

---

## Phase 8: Fleet Control Plane

**Goal:** A lightweight control plane for fleet-wide operations — the "kubectl for claws."

### Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Control Plane                              │
│                                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐              │
│  │ clawctl CLI  │  │ Fleet API   │  │ Grafana      │              │
│  │              │  │ (FastAPI)   │  │ Dashboard    │              │
│  └──────┬───────┘  └──────┬──────┘  └──────┬───────┘              │
│         │                 │                │                       │
│  ┌──────▼─────────────────▼────────────────▼───────┐              │
│  │              Consul (config + discovery)         │              │
│  └──────────────────────┬──────────────────────────┘              │
│                         │                                          │
│  ┌──────────────────────▼──────────────────────────┐              │
│  │              Terraform State (fleet inventory)   │              │
│  └──────────────────────────────────────────────────┘              │
└──────────────────────────────────────────────────────────────────┘
         │              │              │              │
    ┌────▼────┐    ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
    │  alice  │    │   bob   │    │  carol  │    │  dave   │
    │ (Azure) │    │ (Azure) │    │  (AWS)  │    │  (GCP)  │
    │ xfce+VNC│    │ xfce+VNC│    │ xfce+VNC│    │ xfce+VNC│
    │ Chrome  │    │ Chrome  │    │ Chrome  │    │ Chrome  │
    │ OpenClaw│    │ OpenClaw│    │ OpenClaw│    │ OpenClaw│
    └─────────┘    └─────────┘    └─────────┘    └─────────┘
```

### clawctl CLI

```bash
clawctl status                       # fleet overview table
clawctl ssh alice                    # SSH into alice
clawctl vnc alice                    # open VNC to alice
clawctl logs alice -f                # tail agent logs
clawctl health                       # run verify.sh on all claws
clawctl config set alice model xai/grok-4   # hot-reload config via Consul
clawctl upgrade alice --image 2.0.0  # terraform apply for one claw
clawctl pause alice                  # stop agent, keep VM running
clawctl resume alice                 # restart agent
clawctl snapshot alice               # snapshot data disk
clawctl spawn --from alice --name alice-2  # clone: new VM + copy of alice's data disk
```

Under the hood, `clawctl` is a thin CLI that calls Terraform (for infra changes), Consul (for config/discovery), and SSH (for direct VM operations).

---

## Phasing and Dependencies

```
Phase 1: Terraform         ← START HERE. Biggest ROI. No dependencies.
  │
  ├── Phase 2: Packer      ← Can start in parallel with Phase 1.
  │     │
  │     └── Phase 3: CI/CD ← Needs both Terraform and Packer.
  │
  ├── Phase 4: Secrets      ← Independent. Start when fleet > 5 claws.
  │
  ├── Phase 5: Observability ← Independent. Start when you want cost visibility.
  │
  └── Phase 6: Consul       ← Needs fleet > 10 claws to justify.
        │
        ├── Phase 7: Multi-cloud ← Needs Terraform modules. Consul for cross-cloud.
        │
        └── Phase 8: Control Plane ← Needs everything above.
```


---

## What this does NOT include (and why)

- **Kubernetes** — Claws need unrestricted OS access with real desktops. Docker-in-Docker, GPU passthrough, X11 forwarding through containers — all of these add complexity that fights the core product. VMs are the right primitive.
- **Container orchestration** — Same reason. OpenClaw isn't a microservice; it's an agent that needs to click buttons and type in browsers.
- **Auto-scaling** — Claws have persistent identity and state. You don't auto-scale humans; you hire and onboard them. Same with claws: explicitly defined in claws.yaml, provisioned via terraform apply.
- **Serverless** — An agent that needs a persistent desktop, browser state, filesystem, and VNC cannot be serverless.
- **Abstract "agent framework"** — This is infrastructure, not an SDK. OpenClaw is the agent framework. OpenClawps is the ops layer that runs it.

---

## The mental model

Think of OpenClawps as **the IT department for AI employees**.

- **Terraform + claws.yaml** = HR system (who works here, what resources do they get)
- **Packer** = standard-issue laptop image (same base build for everyone)
- **Data disk** = employee's desk, files, and notes (survives laptop swaps)
- **boot.sh** = first-day IT setup (mount their stuff, configure their machine)
- **Consul** = corporate IT policy engine (push config changes fleet-wide)
- **Langfuse** = time tracking / expense reporting (what did they do, what did it cost)
- **verify.sh** = IT health check (is the machine working?)
- **clawctl** = the IT help desk CLI (ssh into any machine, restart services, check status)

Every real IT department has these capabilities. OpenClawps is building the same thing for AI agents running on cloud VMs.
