<p align="center">
  <img src="docs/images/nf-neuro_logo_light.png#gh-light-mode-only" alt="Sublime's custom image"/>
</p> <!-- omit in toc -->
<p align="center">
  <img src="docs/images/nf-neuro_logo_dark.png#gh-dark-mode-only" alt="Sublime's custom image"/>
</p> <!-- omit in toc -->

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![Imports: nf-core](https://img.shields.io/badge/nf--core-nf?label=import&style=flat&labelColor=ef8336&color=24B064)](https://pycqa.github.io/nf-core/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
![Checks](https://github.com/scilus/nf-neuro/workflows/nf-neuro%20merge%20checks/badge.svg)

Welcome to the `nf-neuro` project ! A **Nextflow** modules and workflows repository for neuroimaging
maintained by the [SCIL team](https://scil-documentation.readthedocs.io/en/latest/). The
primary focus of the library is to provide pre-built processes and processing sequences for
**neuroimaging**, optimized for _Nextflow DSL2_, based on open-source
technologies and made easily available to pipeline's developers through the `nf-core`
framework.

* [Using modules from `nf-neuro`](#using-modules-from-nf-neuro)
* [Developing in `nf-neuro`](#developing-in-nf-neuro)
  * [Manual configuration](#manual-configuration)
    * [Dependencies](#dependencies)
    * [Python environment](#python-environment)
    * [Loading the project's environment](#loading-the-projects-environment)
    * [Global environment](#global-environment)
    * [Working with VS Code](#working-with-vs-code)
  * [Configuration via the `devcontainer`](#configuration-via-the-devcontainer)
* [Contributing to the `nf-neuro` project](#contributing-to-the-nf-neuro-project)
  * [Adding a new module to nf-neuro](./docs/MODULE.md#adding-a-new-module-to-nf-neuro)
    * [Generate the template](./docs/MODULE.md#generate-the-template)
    * [Edit the template](./docs/MODULE.md#edit-the-template)
      * [Edit `main.nf`](./docs/MODULE.md#edit-mainnf)
      * [Edit `environment.yml`](./docs/MODULE.md#edit-environmentyml)
      * [Edit `meta.yml`](./docs/MODULE.md#edit-metayml)
    * [Create test cases](./docs/MODULE.md#create-test-cases)
      * [Edit `tests/main.nf.test`](./docs/MODULE.md#edit-testsmainnftest)
      * [Edit `tests/nextflow.config`](./docs/MODULE.md#edit-testsnextflowconfig)
    * [Generate tests snapshots](./docs/MODULE.md#generate-tests-snapshots)
    * [Lint your code](./docs/MODULE.md#lint-your-code)
    * [Submit your PR](./docs/MODULE.md#submit-your-pr)
  * [Defining optional input parameters](./docs/MODULE.md#defining-optional-input-parameters)
  * [Test data infrastructure](./docs/MODULE.md#test-data-infrastructure)
  * [Adding a new subworkflow to nf-neuro](./docs/SUBWORKFLOWS.md#adding-a-new-subworkflow-to-nf-neuro)
    * [Generate the template](./docs/SUBWORKFLOWS.md#generate-the-template)
    * [Edit the template](./docs/SUBWORKFLOWS.md#edit-the-template)
      * [Edit `main.nf`](./docs/SUBWORKFLOWS.md#edit-mainnf)
        * [Define your subworkflow inputs](./docs/SUBWORKFLOWS.md#define-your-subworkflow-inputs)
        * [Fill the `main:` section](./docs/SUBWORKFLOWS.md#fill-the-main-section)
        * [Define your Workflow outputs](./docs/SUBWORKFLOWS.md#define-your-workflow-outputs)
      * [Edit `meta.yml`](./docs/SUBWORKFLOWS.md#edit-metayml)
      * [Create test cases](./docs/SUBWORKFLOWS.md#create-test-cases)
    * [Lint your code](./docs/SUBWORKFLOWS.md#lint-your-code)
    * [Submit your PR](./docs/SUBWORKFLOWS.md#submit-your-pr)
* [Running tests](#running-tests)
* [Configuring Docker for easy usage](#configuring-docker-for-easy-usage)
* [Installing Prettier and editorconfig](#installing-prettier-and-editorconfig)


# Using modules from `nf-neuro`

To import modules from `nf-neuro`, you first need to install [nf-core](https://github.com/nf-core/tools)
on your system (can be done simply using `pip install nf-core`). Once done, `nf-neuro`
modules are imported using this command :

```bash
nf-core modules --git-remote https://github.com/scilus/nf-neuro.git install <category>/<tool>
```

where you input the `<tool>` you want to import from the desired `<category>`. To get
a list of the available modules, run :

```bash
nf-core modules --git-remote https://github.com/scilus/nf-neuro.git list remote
```

The same can be done for subworkflows, replacing `modules` in the `nf-core` command by `subworkflows, e.g. :

```bash
nf-core subworkflows --git-remote https://github.com/scilus/nf-neuro.git install <category>/<subworkflow>
```

It can become heavy to always prepend the commands with `--git-remote`, even so if you need to specify a `--branch` where to fetch the information. You can instead define the `git-remote` and `branch` using _Environment Variables_ :

```bash
export NFCORE_MODULES_GIT_REMOTE=https://github.com/scilus/nf-neuro.git
export NFCORE_MODULES_GIT_BRANCH=main
export NFCORE_SUBWORKFLOWS_GIT_REMOTE=https://github.com/scilus/nf-neuro.git
export NFCORE_SUBWORKFLOWS_GIT_BRANCH=main
```

and call all commands without specifying the `--git-remote` and `--branch` options, while still targeting the `nf-neuro` repository.

# Developing in `nf-neuro`

The `nf-neuro` project requires some specific tools to be installed on your system so that the development environment runs correctly. You can [install them manually](#manual-configuration), but if you desire to streamline the process and start coding faster, we highly recommend using the [VS Code development container](#configuration-via-the-devcontainer) to get fully configured in a matter of minutes.

## Manual configuration

### Dependencies

- Python &geq; 3.8, < 3.13
- Docker &geq; 24 (we recommend using [Docker Desktop](https://www.docker.com/products/docker-desktop))
- Java Runtime &geq; 11, &leq; 17
  - On Ubuntu, install `openjdk-jre-<version>` packages
- Nextflow &geq; 21.04.3
- nf-test &geq; 0.9.0-rc1
- Node &geq; 14 and Prettier (see [below](#installing-prettier))

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
>   following : `/Library/Java/JavaVirtualMachines/dk<inner version>_1<runtime version>.jdk/Contents/Home`.

### Python environment

The project uses _poetry_ to manage python dependencies. To install it using pipx,
run the following commands :

```bash
pip install pipx
pipx ensurepath
pipx install poetry==1.8.*
```

> [!NOTE]
> If the second command above fails, `pipx` cannot be found in the path. Prepend the
> second command with `$(which python) -m` and rerun the whole block.

> [!WARNING]
> Poetry doesn't like when other python environments are activated around it. Make
> sure to deactivate any before calling `poetry` commands.

Once done, install the project with :

```bash
poetry install
```

### Loading the project's environment

> [!IMPORTANT]
> Make sure no python environment is activated before running commands !

The project scripts and dependencies can be accessed using :

```bash
poetry shell
```

which will activate the project's python environment in the current shell.

> [!NOTE]
> You will know the poetry environment is activated by looking at your shell. The
> input line should be prefixed by : `(nf-neuro-tools-py<version>)`, with `<version>`
> being the actual Python version used in the environment.

To exit the environment, simply enter the `exit` command in the shell.

> [!IMPORTANT]
> Do not use traditional deactivation (calling `deactivate`), since it does not relinquish
> the environment gracefully, making it so you won't be able to reactivate it without
> exiting the shell.

### Global environment

Set the following environment variables in your `.bashrc` (or whatever is the equivalent for your shell) :

```bash
export NFCORE_MODULES_GIT_REMOTE=https://github.com/scilus/nf-neuro.git
export NFCORE_MODULES_GIT_BRANCH=main
export NFCORE_SUBWORKFLOWS_GIT_REMOTE=https://github.com/scilus/nf-neuro.git
export NFCORE_SUBWORKFLOWS_GIT_BRANCH=main
```

This will make it so the `nf-core` commands target the right repository by default. Else, you'll need to add `--git-remote` and `--branch` options to pretty much all commands relating to `modules` and `subworkflows`.

### Working with VS Code

The `nf-neuro` project curates a bundle of useful extensions for Visual Studio Code, the `nf-neuro-extensions` package. You can find it easily on the [extension
marketplace](https://marketplace.visualstudio.com/items?itemName=nf-neuro.nf-neuro-extensions).

## Configuration via the `devcontainer`

The `devcontainer` definition for the project contains all required dependencies and setup
steps are automatically executed. To use this installation method, you need to have **Docker** (refer to [this section](#configuring-docker-for-easy-usage) for configuration requirements or validate your configuration) and **Visual Studio Code** installed on your system.

Open the cloned repository in _VS Code_ and click on the arrow box in the lower left corner, to get a prompt to `Reopen in container`. The procedure
will start a docker build, wait for a few minutes and enjoy your fully configured development
environment.

- Available in the container :

  - `nf-neuro`, `nf-core` all accessible through the terminal, which is configured to load
    the `poetry` environment in shells automatically
  - `nf-neuro` configured as the main repository for all `nf-core` commands, using `NFCORE_*` environment variables
  - `git`, `git-lfs`, `github-cli`
  - `curl`, `wget`, `apt-get`
  - `nextflow`, `nf-test`, `docker`, `tmux`

- Available in the VS Code IDE through extensions :
  - Docker images and containers management
  - Python and C++ linting, building and debugging tools
  - Github Pull Requests management
  - Github flavored markdown previewing

# Contributing to the `nf-neuro` project

If you want to propose a new `module` to the repository, follow the guidelines in the [module creation](./docs/MODULE.md) documentation. The same goes for `subworkflows`, using [these guidelines](./docs/SUBWORKFLOWS.md) instead. We follow standards closely aligned with `nf-core`, with some exceptions on process atomicity and how test data is handled. Modules that don't abide to them won't be accepted and PR containing them will be closed automatically.

# Running tests

Tests are run through `nf-core`, using the command :

```bash
nf-core modules test <category/tool>
```

The tool can be omitted to run tests for all modules in a category.

# Configuring Docker for easy usage

The simplest way of installing everything Docker is to use [Docker Desktop](https://www.docker.com/products/docker-desktop). You can also go the [engine way](https://docs.docker.com/engine/install) and install Docker manually.

Once installed, you need to configure some access rights to the Docker daemon. The easiest way to do this is to add your user to the `docker` group. This can be done with the following command :

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
```

After running this command, you need to log out and log back in to apply the changes.

# Installing Prettier and editorconfig

To install **Prettier** and **editorconfig** for the project, you need to have `node` and `npm` installed on your system to at least version 14. On Ubuntu, you can do it using snap :

```bash
sudo snap install node --classic
```

However, if you cannot install snap, or have another OS, refer to the [official documentation](https://nodejs.org/en/download/package-manager/) for the installation procedure.

Under the current configuration for the _Development Container_, for this project, we use the following procedure, considering `${NODE_MAJOR}` is at least 14 for Prettier :

```bash
curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - &&\
apt-get install -y nodejs

npm install --save-dev --save-exact prettier
npm install --save-dev --save-exact editorconfig-checker

echo "function prettier() { npm exec prettier $@; }" >> ~/.bashrc
echo "function editorconfig-checker() { npm exec editorconfig-checker $@; }" >> ~/.bashrc
```
