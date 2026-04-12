# OpenClawOps

ClawOps for OpenClaw agents on Azure. Continuously roll out system updates across a fleet of autonomous agents while preserving each agent's identity, workspace, credentials, and running state.

The pattern: **image = versioned system runtime, detachable disk = durable agent state, boot script = late binding**. Update the image, swap the VM underneath, the agent picks up where it left off.

## How it works

Each claw is an always-on Ubuntu 24.04 VM with a persistent xfce4 desktop, OpenClaw gateway, Telegram bot, Chrome, and Claude Code. The VM runs whether or not anyone is watching. Two SSH or VNC sessions see the same live desktop.

The system layer (OS, packages, OpenClaw, boot logic) is baked into a versioned image. Everything that makes a claw *that specific claw* (config, secrets, workspace, memory, session state) lives on a detachable Azure managed disk. Upgrades swap the image; the data disk rides along.

## Lifecycle

### Build from scratch

```bash
cp .env.template .env && vi .env
./deploy.sh scratch
```

Full install from stock Ubuntu. ~10 min. When done, message the Telegram bot.

### Bake the image

```bash
./deploy.sh bake 1.0.0
```

Strips secrets, captures the system as a versioned image in Azure Compute Gallery.

### Stamp out claws

```bash
ENV_FILE=.env.alice VM_NAME=alice ./deploy.sh
ENV_FILE=.env.bob   VM_NAME=bob   ./deploy.sh
```

~2 min each. Fresh data disk, own credentials, own Telegram bot, fully independent.

### Roll out updates

```bash
# Bake a new version from an updated VM
./deploy.sh bake 2.0.0

# Upgrade a claw in place -- data disk reattaches, state preserved
./deploy.sh upgrade alice --image 2.0.0
```

Numbered migration scripts in `updates/` run automatically on the data disk after each upgrade.

## Credentials per claw

| Credential | Purpose |
|---|---|
| `TELEGRAM_BOT_TOKEN` | Each claw is a different bot (@BotFather) |
| `XAI_API_KEY` | Model provider (can share across claws) |
| `OPENAI_API_KEY` | Optional |
| `BRIGHTDATA_API_TOKEN` | Optional, web research |
| `TELEGRAM_USER_ID` | Optional, restricts who can DM the bot |
| `VM_PASSWORD` | Optional, auto-generated. Single password for SSH and VNC. |

## Prerequisites

- Azure CLI (`az login`)
- `envsubst` (`brew install gettext`)
- `sshpass` (deploy-time automation only -- VMs accept plain `ssh azureuser@ip` from anywhere)

## Connect

```bash
ssh azureuser@<ip>          # password printed at deploy time, saved in .vm-state
open vnc://<ip>:5900        # same password
```

## Stop / start

```bash
az vm deallocate -g rg-linux-desktop -n alice   # billing stops
az vm start      -g rg-linux-desktop -n alice   # everything resumes
```

Nothing reinstalls. Systemd services auto-start. Data disk stays attached.

## Security posture

Deliberately permissive inside the VM. OpenClaw runs unrestricted: sandbox off, full exec rights, passwordless sudo. The agent operates as if it were a human at the keyboard.

Containment is at the infrastructure boundary: isolated resource group, scoped credentials, narrow managed identity. The VM is not the security boundary -- Azure is.

## Destroy

```bash
az vm delete -g rg-linux-desktop -n alice --yes                    # one claw
az group delete --name rg-linux-desktop --yes --no-wait            # everything
```
