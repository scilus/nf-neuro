# Prototyping environment setup

> [!NOTE]
> `Nextflow` chose [VS Code](https://code.visualstudio.com) as its main development IDE (with good reasons), give
> its extension capabilities, ease of use, great look (well, it counts) and openness. We highly recommend you to
> use it to develop. Give it a try, we guarantee you'll adopt it eventually.

> [!IMPORTANT]
> We highly recommend using the integrated `development container` designed to streamline your installation
> and support your development through `VS Code`. To setup yourself, refer to [this section](./docs/DEVCONTAINER.md)
> and skip the whole environment setup.

* [Prototyping environment setup](#prototyping-environment-setup)
  * [Dependencies](#dependencies-)
  * [Configuration](#configuration-)


## Dependencies

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

## Configuration

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
