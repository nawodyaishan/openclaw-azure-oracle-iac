# Technical Specification Document: OpenClaw Oracle Deployer TUI App

## Document Metadata
- **Version**: 1.0
- **Date**: February 22, 2026
- **Project Name**: OpenClaw Deployer (TUI Wrapper)
- **Description**: This document outlines the technical specifications for a Terminal User Interface (TUI) application that simplifies the deployment and management of OpenClaw on Oracle Cloud Infrastructure (OCI) Free Tier VMs. The app is built in Go, distributed as a Homebrew package, and focuses on dependency management, OCI configuration, automated deployment using existing IaC (Terraform and Packer), progress reporting, and post-deployment interaction with OpenClaw inside the VM.
- **Scope**: Oracle Cloud Free Tier and Azure (expanding on the existing `openclaw-azure-iac` modules).
- **Assumptions**: Users are on macOS/Linux (Homebrew-compatible). The app wraps the Packer and Terraform templates from the existing repository.

## 1. High-Level Requirements
### Functional Requirements
- **Dependency Management**:
  - Check for required tools: Terraform, Packer, OCI CLI, Azure CLI.
  - If missing, prompt to install via Homebrew (e.g., `brew install hashicorp/tap/terraform`).
  - Validate installations by checking versions and PATH mapping.
- **Cloud Configuration Setup**:
  - Guide users through creating or editing `~/.oci/config` (INI format) and `az login`.
  - Interactive prompts for required fields: `user`, `fingerprint`, `key_file`, `tenancy`, `region`.
- **Deployment Workflow**:
  - Wrap the existing Packer (`packer/oracle`) and Terraform (`environments/dev/oracle`) runbooks via `os/exec`.
  - Interactive setup: Prompt for `compartment_ocid`, `allowed_ssh_cidr` (auto-detect via `curl ifconfig.me`), and SSH keys.
  - Generate variables dynamically to `terraform.tfvars`.
  - Handle common errors (e.g., "Out of Host Capacity" via recursive retries checking AD grids).
- **Progress Reporting**:
  - Real-time Bubbletea UI updates: Progress bars for Packer build, Terraform apply.
  - Log viewer: Display parsed stdout/stderr in a scrollable view.
- **Post-Deployment Interaction**:
  - Trigger direct SSH bridges.
  - Present `GATEWAY_TOKEN` securely to the terminal immediately upon successful apply logic.
  - Integrated state management options (Destroy, Plan, Validate).

### Non-Functional Requirements
- **Platform**: Cross-platform (MacOS / Linux), Homebrew installable.
- **Security**: Strict zero-trust modeling. No credentials ever hardcoded or printed to log wrappers. Only interfaces with `~/.oci/config` and local environments naturally.
- **Maintainability**: Go embeddings where required, though directly interacting with Make targets provides backwards CLI compatibility.

## 2. Architecture Overview
### System Components
- **Frontend (TUI)**: `charmbracelet/bubbletea` for reactive component modeling.
- **Backend Logic**:
  - Dependency Checker: `os/exec` to validate env constraints.
  - IaC Runner: Maps Bubbletea UI models down to the underlying `Makefile` targets (`make build-oracle`, `make deploy-oracle`).
  - SSH Proxy: `golang.org/x/crypto/ssh` for immediate session dropping post-deployment.
- **State Management**: Bubbletea's generic Model struct controls navigation pipelines.

### High-Level Flow
```text
[Main Menu] -> [Prerequisite Checker] -> [Cloud Auth Validation] -> [Variable Prompter]
                                                                        |
[Post-Deploy UI] <- [Terraform Output Parser] <- [Terraform Apply] <- [Packer Build]
(SSH/Token/Logs)
```

## 3. Technology Stack
- **Language**: Go (v1.22+).
- **TUI Framework**: `charmbracelet/bubbletea`, `charmbracelet/lipgloss`, `charmbracelet/bubbles`.
- **Process Execution**: Standard `os/exec`.
- **Packaging**: GoReleaser generating native Homebrew Tap formulas.

## 4. Proposed Implementation Architecture
The cleanest strategy connects Go as a pure Controller wrapper that leverages your exact, perfectly refactored `Makefile`. 
Instead of trying to rewrite the IaC logic in pure Go SDK requests, the Go application simply acts as a gorgeous UI that automates the tedious data entry of `.tfvars` mapping.

1. App checks if `terraform` and `packer` exist.
2. App reads active public IP and auto-maps `allowed_ssh_cidr`.
3. App asks user: "Which cloud do you want to deploy to?" -> (Oracle / Azure).
4. App modifies the `environments/dev/oracle/terraform.tfvars` file natively using Go primitives.
5. App runs `exec.Command("make", "build-oracle")` while parsing the stdout into a Bubbletea progress bar.
6. Upon completion, extracts the Packer AMI and writes it to `.tfvars`.
7. App runs `exec.Command("make", "deploy-oracle")` tracking progress.
8. Displays the beautiful final connection screen parsing Terraform output tokens.
