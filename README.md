# My Dotfiles

Personal configuration for devcontainers.

## Setup

1. Add to VS Code User Settings (`Ctrl+Shift+P` → "Preferences: Open User Settings (JSON)"):

   ```json
   {
     "dotfiles.repository": "esimkowitz/dotfiles",
     "dotfiles.installCommand": "install.sh",
     "dev.containers.defaultMounts": [
       "source=${localEnv:SSH_AUTH_SOCK},target=/ssh-agent,type=bind"
     ],
     "dev.containers.containerEnv": {
       "SSH_AUTH_SOCK": "/ssh-agent"
     }
   }
   ```

2. Rebuild any devcontainer

## What it does

- Detects if SSH agent is available (mounted from WSL/Linux host)
- Configures git to use SSH signing when agent is present
- Skips signing setup gracefully on Windows hosts without agent forwarding
