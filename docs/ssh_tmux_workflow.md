# SSH & Tmux Master Workflow

This guide covers the industry-standard workflow for connecting to your OpenClaw virtual machines securely using SSH keys, and maximizing your productivity using `tmux` (Terminal Multiplexer), which is pre-installed on all our Golden Images.

By following this workflow, your terminal sessions will persist even if your WiFi drops or your laptop goes to sleep.

---

## Part 1: Secure SSH Connection

Your OpenClaw infrastructure is locked down. Password authentication is disabled by design. You can only access the VM using the private SSH key corresponding to the public key you provided in `terraform.tfvars`.

### 1. Connecting via the Makefile (Recommended)
The easiest way to connect is using our built-in Makefile targets. They automatically query the Terraform state for the public IP address and establish the connection using the correct user.

```bash
# To connect to your Azure VM:
make ssh-azure

# To connect to your Oracle Cloud VM:
make ssh-oracle
```

### 2. Manual Connection
If you need to connect manually (e.g., from a different machine or a script), you can find the IP address in your Terraform outputs (`make output-[cloud]`).

* **Azure Username:** `azureuser`
* **Oracle Username:** `ubuntu`

```bash
# Syntax: ssh -i <path_to_private_key> <user>@<ip_address>
ssh -i ~/.ssh/id_rsa ubuntu@150.136.251.226
```

> [!TIP]
> Ensure your private key has strict permissions, or ssh will reject it:
> `chmod 400 ~/.ssh/id_rsa`

---

## Part 2: The Tmux Workflow (Zero Downtime)

When you run long processes (like the `openclaw` application or training scripts) over a standard SSH connection, the process will die immediately if your SSH connection drops.

**Tmux solves this.** It creates a persistent "shell within a shell" on the remote server.

### 1. Starting a Tmux Session
As soon as you SSH into your VM, your primary reflex should be to start or attach to a tmux session.

```bash
# 1. SSH into the VM
make ssh-oracle

# 2. Create a new tmux session named "openclaw"
tmux new -s openclaw
```

You are now inside the tmux session! The green bar at the bottom indicates you are running inside the multiplexer. You can safely start the OpenClaw service here.

```bash
# Start the service inside tmux
openclaw start
```

### 2. Detaching (Leaving it running in the background)
You can now safely "detach" from the session. The OpenClaw application will continue running in the background infinitely.

* Press `Ctrl + B`, let go of both keys, then press `D` (for Detach).

You will be dropped back to the normal SSH prompt, and you can safely `exit` the server entirely.

### 3. Re-Attaching (Resuming your work)
When you SSH back into the server later, your application will still be running exactly as you left it. Re-attach to the session to see its live output.

```bash
# List running sessions
tmux ls

# Re-attach to the "openclaw" session
tmux attach -t openclaw
```

---

## Part 3: Tmux Cheat Sheet for Power Users

Tmux uses a "Prefix" key combo before every command. 
The default Prefix is **`Ctrl + B`**. You must press and release `Ctrl + B` before pressing the command key.

### Window Management (Tabs)
Instead of opening multiple SSH connections, use Tmux Windows:
* `Prefix` then `c`: **Create** a new window (tab).
* `Prefix` then `n`: Go to the **Next** window.
* `Prefix` then `p`: Go to the **Previous** window.
* `Prefix` then `[Number]`: Jump to window 0, 1, 2, etc.
* `Prefix` then `&`: Kill the current window.

### Pane Management (Split Screen)
You can split a single window into multiple panes to view logs while editing files.
* `Prefix` then `%`: Split pane **Vertically** (left/right).
* `Prefix` then `"`: Split pane **Horizontally** (top/bottom).
* `Prefix` then `Arrow Keys`: Move focus between panes.
* `Prefix` then `x`: Kill the current pane.
* `Prefix` then `z`: **Zoom** the current pane to full screen (press again to un-zoom).

### Scrolling History
By default, scrolling with your mouse simply scrolls your local terminal history, not the remote tmux history. To scroll within tmux:
1. `Prefix` then `[` (enters "Copy Mode").
2. Use the `Up / Down` arrows or `PageUp / PageDown` to scroll through your logs.
3. Press `q` to quit scrolling mode and return to the live prompt.

---

## Summary of the Ultimate Workflow
1. Run `make ssh-oracle` from your laptop.
2. Run `tmux attach -t openclaw || tmux new -s openclaw`.
    * *(This smartly attaches to an existing session, or creates it if it doesn't exist)*.
3. Do your work, start your servers.
4. Press `Ctrl+B`, `D` to detach safely.
5. Close your laptop. The server keeps running flawlessly.

---

## Part 4: Architectural History & Troubleshooting (SSH Key Injection)

During the migration to our zero-secret infrastructure model, we encountered a critical scenario where the deployment succeeded, but SSH access was immediately denied (`Permission denied (publickey)`). Here is what happened and how it was resolved in our Terraform configurations.

### The Problem
1. **Missing Local Key:** The local machine did not have a standard RSA key pair (`~/.ssh/id_rsa`). This was resolved by generating a new 4096-bit RSA key.
2. **Missing Inbound Injection:** Even after generating the key, access was denied. This happened because during our massive refactoring to remove hardcoded OCI credentials, we accidentally removed the Terraform logic responsible for pushing the *local public key* to the *remote VM*.

### The Infrastructure Fix
To fix this without regressing our security posture (no private keys in codebase), we updated the Terraform deployment to dynamically read the local public key string and inject it into the VM during the `cloud-init` bootstrapping phase.

**1. `infra/oracle/variables.tf`**
We re-introduced the variable tracking the location of the *public* key on your local filesystem: 
```hcl
variable "ssh_public_key_path" {
  description = "Path to the SSH public key for VM auth"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
```

**2. `infra/oracle/terraform.tfvars`**
We explicitly declared this mapping so engineers can clearly see where their key is sourced from:
```hcl
ssh_public_key_path = "~/.ssh/id_rsa.pub"
```

**3. `infra/oracle/main.tf`**
We updated the core compute instance block to natively read the *string contents* of that public key file using Terraform's `file()` function, and mapped it into the `ssh_authorized_keys` metadata block alongside our Gateway Token injection.
```hcl
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data = base64encode(templatefile("${path.module}/cloud-init.tftpl", { ... }))
  }
```

By tearing down and replacing the instance with this updated script, the cloud provider natively wrote our `id_rsa.pub` into the `ubuntu` user's `~/.ssh/authorized_keys` file at boot-time, completely solving the authentication drop.
