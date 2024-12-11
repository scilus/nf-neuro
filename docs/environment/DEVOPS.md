# Developing within `nf-neuro`

The `nf-neuro` project requires some specific tools to be installed on your system so that the development environment runs correctly. You can [install them manually](#manual-configuration), but if you desire to streamline the process and start coding faster, we highly recommend using the [VS Code development container](./docs/DEVCONTAINER.md#development-environment) to get fully configured in a matter of minutes.

## Manual configuration

### Dependencies

- Python &geq; 3.8, < 3.13
- Docker &geq; 24 (we recommend using [Docker Desktop](https://www.docker.com/products/docker-desktop))
- Java Runtime &geq; 11, &leq; 17
  - On Ubuntu, install `openjdk-jre-<version>` packages
- Nextflow &geq; 23.04.0
- nf-test &geq; 0.9.0
- Node &geq; 14, `Prettier` and `editorconfig` (see [below](#installing-prettier-and-editorconfig))

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

### Python environment

The project uses _poetry_ to manage python dependencies. To install it using pipx,
run the following commands :

```bash
pip install pipx
pipx ensurepath
pipx install poetry==1.8.-
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
marketplace](https://marketplace.visualstudio.com/items?itemName=nf-neuro.nf-neuro-extensionpack).


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
