# `Prototyping` development container<!-- omit in toc -->

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

> [!WARNING]
> The `prototyping` environment definition is not meant to be run from the `nf-neuro` repository root.
> Locate your project elsewhere (we recommend putting it outside this directory to prevent
> conflicts with `git`).

- Copy the **devcontainer** definition path at `.devcontainer/prototyping` and its content inside your project
  - the target path in your project should be `<project_dir>/.devcontainer/prototyping`
- Open your project with **VS CODE**
  - create a new window with **File > New Window** or `ctrl+shift+N`, then use **File > Open Folder**.
- Click on the **blue box** in the lower left corner, to get a prompt to `Reopen in container`
  - alternatively, open the **command palette** with `ctrl+shit+P` and start typing `Reopen in ...` to filter in
    and select the command

The procedure will start a docker build, wait for a few minutes and enjoy your fully configured development environment.

## Available in the container

- `nf-core` accessible through the terminal, which is configured to access `nf-neuro` modules and subworkflows
- `git`, `github-cli`
- `curl`, `wget`, `apt-get`
- `nextflow`, `docker`, `tmux`

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
