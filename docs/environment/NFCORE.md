# Basic environment setup

- [Basic environment setup](#basic-environment-setup)
  - [Development container](#development-container)
  - [Manual installation](#manual-installation)
    - [Dependencies](#dependencies)
    - [Configuration](#configuration)

## Development container

A lightweight `development container` that setups you in a matter of minutes is [available here](./DEVCONTAINER.md#prototyping-environment).

## Manual installation

### Dependencies

- Python &geq; 3.8, < 3.13
- Docker &geq; 24 (we recommend using [Docker Desktop](https://www.docker.com/products/docker-desktop))
- Java Runtime &geq; 11, &leq; 17
  - On Ubuntu, install `openjdk-jre-<version>` packages
- Nextflow &geq; 23.04.0

> [!IMPORTANT]
> Nextflow might not detect the right `Java virtual machine` by default, more so if
> multiple versions of the runtime are installed. If so, you need to set the environment
> variable `JAVA_HOME` to target the right one.
>
> - Linux : look in `/usr/lib/jvm` for
>   a folder named `java-<version>-openjdk-<platform>` and use it as `JAVA_HOME`.
> - MacOS : if the `Java jvm` is the preferential one, use `JAVA_HOME=$(/usr/libexec/java_home)`.
>   Else, look into `/Library/Java/JavaVirtualMachines` for the folder with the correct
>   runtime version (named `jdk<inner version>_1<runtime version>.jdk`) and use the
>   following : `/Library/Java/JavaVirtualMachines/jdk<inner version>_1<runtime version>.jdk/Contents/Home`.

### Configuration

Install `nf-core` in your `python` environment (we recommend using a `virtual environment`) :

```bash
pip install nf-core==2.14.1
```

Configure your current environment so `nf-core` commands have access to `nf-neuro` modules :

```bash
export NFCORE_MODULES_GIT_REMOTE=https://github.com/scilus/nf-neuro.git
export NFCORE_MODULES_GIT_BRANCH=main
export NFCORE_SUBWORKFLOWS_GIT_REMOTE=https://github.com/scilus/nf-neuro.git
export NFCORE_SUBWORKFLOWS_GIT_BRANCH=main
```
