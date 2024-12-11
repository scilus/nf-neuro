# Using `nf-neuro` development containers

`nf-neuro` comes preloaded with a set of development containers destined at streamlining
your development. They provide `pre-installed` environments for you to start programming
new `pipelines` or `nf-neuro components`.

- [Using `nf-neuro` development containers](#using-nf-neuro-development-containers)
  - [Requirements](#requirements)
    - [Configuring Docker for easy usage](#configuring-docker-for-easy-usage)
  - [Prototyping environment](#prototyping-environment)
  - [Production environment](#production-environment)
  - [Development environment](#development-environment)

## Requirements

- [VS Code](https://code.visualstudio.com) &geq; 1.95
- [Docker](https://www.docker.com/get-started/) &geq; 24 (we recommend using [Docker Desktop](https://www.docker.com/products/docker-desktop))

### Configuring Docker for easy usage

The simplest way of installing everything Docker is to use [Docker Desktop](https://www.docker.com/products/docker-desktop). You can also go the [engine way](https://docs.docker.com/engine/install) and install Docker manually.

Once installed, you need to configure some access rights to the Docker daemon. The easiest way to do this is to add your user to the `docker` group. This can be done with the following command :

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
```

After running this command, you need to log out and log back in to apply the changes.

## Prototyping environment

To use the prototyping environment, you can either `clone the nf-neuro repository` or `copy the .devcontainer`
definition contained in the `.devcontainer/prototyping` directory into a `.devcontainer` folder located in your
development environment. Then, open you development directory with _VS CODE_ and click on the arrow box in the
lower left corner, to get a prompt to `Reopen in container` (you'll may need to select the `prototyping`
devcontainer). The procedure will start a docker build, wait for a few minutes and enjoy your fully configured
development environment.

- Available in the container :

  - `nf-core` accessible through the terminal, which is configured to access `nf-neuro` modules and subworkflows
  - `git`, `github-cli`
  - `curl`, `wget`, `apt-get`
  - `nextflow`, `docker`, `tmux`

- Available in the VS Code IDE through extensions :
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

## Production environment

SECTION TO COME

## Development environment

To use the development environment, you need to have the repository cloned. You can do it using
_VS Code_. Once opened in _VS CODE_, click on the arrow box in the lower left corner, to get a prompt to
`Reopen in container`. Select the `devops` container. The procedure will start a docker build, wait for a
few minutes and enjoy your fully configured development environment.

- Available in the container :

  - `nf-neuro`, `nf-core` all accessible through the terminal, which is configured to load
    the `poetry` environment in shells automatically
  - `nf-neuro` configured as the main repository for all `nf-core` commands, using `NFCORE_-` environment variables
  - `git`, `github-cli`
  - `curl`, `wget`, `apt-get`
  - `nextflow`, `nf-test`, `docker`, `tmux`

- Available in the VS Code IDE through extensions :
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
