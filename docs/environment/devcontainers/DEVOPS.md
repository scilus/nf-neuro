# `DEVOPS` development container<!-- omit in toc -->

- [Requirements](#requirements)
  - [Configure Docker access](#configure-docker-access)
- [Usage](#usage)
- [Available in the container](#available-in-the-container)
- [Available in the VS Code IDE through extensions](#available-in-the-vs-code-ide-through-extensions)

## Requirements

- [VS Code](https://code.visualstudio.com) &geq; 1.95
- [Docker](https://www.docker.com/get-started/) &geq; 24 (we recommend using [Docker Desktop](https://www.docker.com/products/docker-desktop))

### Configure Docker access

The simplest way of installing everything Docker is to use [Docker Desktop](https://www.docker.com/products/docker-desktop). You can also go the [engine way](https://docs.docker.com/engine/install) and install Docker manually.

Once installed, you need to configure some access rights to the Docker daemon. The easiest way to do this is to add your user to the `docker` group. This can be done with the following command :

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
```

After running this command, you need to log out and log back in your terminal to apply the changes.

## Usage

- Clone the `nf-neuro` repository locally and open it in `VS Code`
  - alternatively, use `VS Code` directly to clone the repository and pre-configure the environment
- Click on the **blue box** in the lower left corner, to get a prompt to `Reopen in container`
  - alternatively, open the **command palette** with `ctrl+shit+P` and start typing `Reopen in ...` to filter in
    and select the command
- Select the `devops` devcontainer

The procedure will start a docker build, wait for a few minutes and enjoy your fully configured development environment.

## Available in the container

- `nf-neuro`, `nf-core` all accessible through the terminal, which is configured to load
  the `poetry` environment in shells automatically
- `nf-neuro` configured as the main repository for all `nf-core` commands, using `NFCORE_-` environment variables
- `git`, `github-cli`
- `curl`, `wget`, `apt-get`
- `nextflow`, `nf-test`, `docker`, `tmux`

## Available in the VS Code IDE through extensions

- Docker images and containers management
- Nextflow execution environemnt
- Python and C++ linting, building and debugging tools
- Github Pull Requests management
- Github flavored markdown previewing
- Neuroimaging data viewer
- Test Data introspection
- Resource monitoring
- Remote development
- Live sharing with collaborators
