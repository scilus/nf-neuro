<p align="center">
  <img src="docs/images/nf-neuro_logo_light.png#gh-light-mode-only" alt="Sublime's custom image"/>
</p>
<p align="center">
  <img src="docs/images/nf-neuro_logo_dark.png#gh-dark-mode-only" alt="Sublime's custom image"/>
</p>

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![Imports: nf-core](https://img.shields.io/badge/nf--core-nf?label=import&style=flat&labelColor=ef8336&color=24B064)](https://pycqa.github.io/nf-core/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
![Checks](https://github.com/scilus/nf-neuro/workflows/Merge%20to%20main%20checks/badge.svg)

Welcome to the `nf-neuro` project ! A **Nextflow** modules and workflows repository for neuroimaging
maintained by the [SCIL team](https://scil-documentation.readthedocs.io/en/latest/). The
primary focus of the library is to provide pre-built processes and processing sequences for
**neuroimaging**, optimized for _Nextflow DSL2_, based on open-source
technologies and made easily available to pipeline's developers through the `nf-core`
framework.

# WHY ? `nf-neuro`

**Let's say you develop a pipeline for neuroimaging**. You want to make it the more _efficient,_
_reliable, reproducible_ and also be able to _evaluate it_ and _control the quality_ of its outputs.
That's what `nf-neuro` provides to you, **all in one repository**, hosting **all dependencies** you
need to start developing and analyzing.

The only thing we ask of you is to develop in `Nextflow DSL2`. We use principle and standards
closely aligned with [nf-core](), but we'll make you adapt to them slowly as you go (we still
haven't finished complying to all of them ourselves). Using `nf-neuro` helps accelerate
development in **neuroimaging** and produces better research outcomes for all !

## Where do I start ?

Check out [our documentation](https://scilus.github.io/nf-neuro/) ! You will find everything you need to build your **own module**, create a **subworkflow** or create your **own pipeline** using `nf-neuro` components!

## Contributing to the `nf-neuro` project

`nf-neuro` accepts contribution of new **modules** and **subworkflows** to its library. You'll need first to
[setup your environment](https://scilus.github.io/nf-neuro/guides/nfneuro_devcontainer/), for which we have devised clever ways to streamline the procedure.
Then, depending on which kind of component you want to submit, you'll either need to follow the [module creation](https://scilus.github.io/nf-neuro/guides/create-your-module/template/)
or the [subworkflow creation](https://scilus.github.io/nf-neuro/guides/subworkflows/) guidelines. Components that don't abide to them won't be accepted
and PR containing them will be closed automatically.
