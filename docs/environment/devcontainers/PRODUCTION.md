# `Prototyping` development container<!-- omit in toc -->

- [Requirements](#requirements)
  - [Configure Docker access](#configure-docker-access)
- [Production environment](#production-environment)

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

SECTION TO COME

