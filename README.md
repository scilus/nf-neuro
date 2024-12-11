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

# Where do I start ?

Well, it depends on what you want to do. If you want to :

- Learn about the content of `nf-neuro`, go to the [discovery](#discovering-nf-neuro) section.
- Use **modules** and **subworkflows** from `nf-neuro`, go to the
 [prototyping](#prototyping-using-components-from-nf-neuro) section.
- Fully **publish** your pipeline and **brand** it with `nf-neuro`, go to the
  [porting prototypes](#porting-prototypes-to-nf--ready-pipelines) section.
- Contribute new **modules** and **subworkflows** to the `nf-neuro` **library**, go to the
  [contribution](#contributing-to-the-nf-neuro-project) section.

---

- [WHY ? `nf-neuro`](#why--nf-neuro)
- [Pipeline creation with `nf-neuro`](#pipeline-creation-with-nf-neuro)
  - [Prototyping using components from `nf-neuro`](#prototyping-using-components-from-nf-neuro)
    - [Environment setup](#environment-setup)
      - [Dependencies](#dependencies-)
      - [Configuration](#configuration-)
    - [Using components from `nf-neuro`](#using-components-from-nf-neuro)
      - [Using the information from the `info` command](#using-the-information-from-the-info-command)
  - [Porting prototypes to `nf-` ready pipelines](#porting-prototypes-to-nf--ready-pipelines)
- [Developing with `nf-neuro`](#developing-with-nf-neuro)
  - [Manual configuration](#manual-configuration)
    - [Dependencies](#dependencies)
    - [Python environment](#python-environment)
    - [Loading the project's environment](#loading-the-projects-environment)
    - [Global environment](#global-environment)
    - [Working with VS Code](#working-with-vs-code)
  - [Configuration via the `devcontainer`](#configuration-via-the-devcontainer)
- [Contributing to the `nf-neuro` project](#contributing-to-the-nf-neuro-project)
  - [Adding a new module to nf-neuro](./docs/MODULE.md#adding-a-new-module-to-nf-neuro)
    - [Generate the template](./docs/MODULE.md#generate-the-template)
    - [Edit the template](./docs/MODULE.md#edit-the-template)
      - [Edit `main.nf`](./docs/MODULE.md#edit-mainnf)
      - [Edit `environment.yml`](./docs/MODULE.md#edit-environmentyml)
      - [Edit `meta.yml`](./docs/MODULE.md#edit-metayml)
    - [Create test cases](./docs/MODULE.md#create-test-cases)
      - [Edit `tests/main.nf.test`](./docs/MODULE.md#edit-testsmainnftest)
      - [Edit `tests/nextflow.config`](./docs/MODULE.md#edit-testsnextflowconfig)
    - [Generate tests snapshots](./docs/MODULE.md#generate-tests-snapshots)
    - [Request for more test resources](./docs/MODULE.md#request-for-more-test-resources)
    - [Lint your code](./docs/MODULE.md#lint-your-code)
    - [Submit your PR](./docs/MODULE.md#submit-your-pr)
  - [Defining optional input parameters](./docs/MODULE.md#defining-optional-input-parameters)
  - [Test data infrastructure](./docs/MODULE.md#test-data-infrastructure)
  - [Adding a new subworkflow to nf-neuro](./docs/SUBWORKFLOWS.md#adding-a-new-subworkflow-to-nf-neuro)
    - [Generate the template](./docs/SUBWORKFLOWS.md#generate-the-template)
    - [Edit the template](./docs/SUBWORKFLOWS.md#edit-the-template)
      - [Edit `main.nf`](./docs/SUBWORKFLOWS.md#edit-mainnf)
        - [Define your subworkflow inputs](./docs/SUBWORKFLOWS.md#define-your-subworkflow-inputs)
        - [Fill the `main:` section](./docs/SUBWORKFLOWS.md#fill-the-main-section)
        - [Define your Workflow outputs](./docs/SUBWORKFLOWS.md#define-your-workflow-outputs)
      - [Edit `meta.yml`](./docs/SUBWORKFLOWS.md#edit-metayml)
      - [Create test cases](./docs/SUBWORKFLOWS.md#create-test-cases)
    - [Lint your code](./docs/SUBWORKFLOWS.md#lint-your-code)
    - [Submit your PR](./docs/SUBWORKFLOWS.md#submit-your-pr)
- [Running tests](#running-tests)
- [Configuring Docker for easy usage](#configuring-docker-for-easy-usage)
- [Installing Prettier and editorconfig](#installing-prettier-and-editorconfig)

---

# Discovering `nf-neuro`

To get information on `nf-neuro` components, you'll first need to install `python` and `nf-core`. We provide
extensive guidelines to do it in [this guide](./docs/environment/PROTOTYPING.md).

## Getting info on components from `nf-neuro`

With your environment ready, you can list `nf-neuro` modules and subworkflows with :

```bash
nf-core modules list remote
nf-core subworkflows list remote
```

To get more information on a module (say `denoising/nlmeans`) or a subworkflow (say `preproc_t1`), use :

```bash
nf-core modules info denoising/nlmeans
nf-core subworkflows info preproc_t1
```

> [!NOTE]
> Additionally, `VS Code` users can install the [nextflow extension](https://marketplace.visualstudio.com/items?itemName=nextflow.nextflow),
> which contains a language server that helps you in real time when coding. It gives you useful tooltips on modules inputs and outputs, commands
> to navigate between modules and workflows and highlights errors. For sure, you get all that for free if you use the `devcontainer` !

> [!IMPORTANT]
> The `nextflow language server` is a precious resource that will help you resolve most exceptions existing within the metadata
> description of modules and workflows prescribed by `nf-core` and shown below. Thus, we highly recommend its use.

You'll get a good description of the modules's or subworkflow's `behavior` and `dependencies`, as well as a
thorough description of its `inputs` and `outputs`. To use them in your own pipeline, you need first to
install them locally :

```bash
nf-core modules install denoising/nlmeans
nf-core subworkflows install preproc_t1
```

> [!WARNING]
> You need to be at the root of your `pipeline directory` when calling this command ! `nf-core` installs
> locally to your pipeline's `modules` and `subworkflows`, not in a special hidden place !

> [!NOTE]
> On the first run of the `install` command, select `pipeline` as an install setup. The interactive prompt
> will also ask you to create multiple files and directories. Say yes to everything !

> [!IMPORTANT]
> The installation procedure will provide you an `include` line to add to your pipeline's `main.nf`
> file, which will import the module or subworkflow at runtime.

### Using the information from the `info` command

For a `module`, the list of `inputs` tell you the content to provide in `a single channel`, usually
as a list of lists, each starting with a `meta`, a map `[:]` of metadata containing a mandatory `id` :

```nextflow
// Example for denoising/nlmeans
input = Channel.of( [
    [ [id: "sub-1"], file("image1.nii.gz"), file("mask1.nii.gz") ],
    [ [id: "sub-2"], file("image2.nii.gz"), file("mask2.nii.gz") ]
] )

DENOSING_NLMEANS( input )
```

> [!WARNING]
> There are some exceptions here, due to limitations in current `nf-core` tools and standards.
>
> 1. some inputs could be associated to different channels. It's almost never the case, but it happens.
>    We are working hard at changing the behavior of those modules, and at improving the metadata to
>    help you better. For now, please refer to their implementation in the `modules/nf-neuro/`
>    directory as well, through the `main.nf` file, or given by the `nextflow language server tooltips`.

For the `module's` list of `outputs`, each corresponds to its own `named channel` :

```nextflow
// Example for denoising/nlmeans
DENOISING_NLMEANS.out.image.view()            // [ [ [id: "sub-1"], "sub-1_denoised.nii.gz" ],
                                              //   [ [id: "sub-2"], "sub-2_denoised.nii.gz" ]  ]
DENOISING_NLMEANS.out.versions.first().view() // [ "versions.yml" ]
```

> [!WARNING]
> There are some exceptions here, due to limitations in current `nf-core` tools and standards.
>
> 1. `meta` output **is not a channel** but accompanies all files, produced by other channels.
> 2. `versions` is a channel, but its output is not accompanied by `meta`
> 3. Some other outputs are not accompanied by `meta` also. We are currently improving the metadata
>    files to make it apparent. For now, please refer to their implementation in the `modules/nf-neuro/`
>    directory, through the `main.nf` file.

For `subworkflows` there are no exceptions, nor differences between `inputs` and `outputs`; they are all
`named channels`. Each comes with a `Structure` description, telling you the content to put in the `list of lists`.
For `preproc_t1`, a simple example would be :

```nextflow
ch_image = Channel.of( [
    [ [id: "sub-1"], file("image1.nii.gz") ],
    [ [id: "sub-2"], file("image2.nii.gz") ]
] )

ch_template = Channel
    .of( [ [id: "sub-1"], [id: "sub-2"] ] )
    .combine( [ file("template.nii.gz") ] )
    .view()   // [ [ [id: "sub-1"], "template.nii.gz" ],
              //   [ [id: "sub-2"], "template.nii.gz" ]  ]

ch_probability_map = Channel
    .of( [ [id: "sub-1"], [id: "sub-2"] ] )
    .combine( [ file("probmap.nii.gz") ] )
    .view()   // [ [ [id: "sub-1"], "probmap.nii.gz" ],
              //   [ [id: "sub-2"], "probmap.nii.gz" ]  ]

PREPROC_T1(
    ch_image
    ch_template,
    ch_probability_map
)

PREPROC_T1.out.t1_final.view()          // [ [ [id: "sub-1"], "sub-1_t1_cropped.nii.gz" ],
                                        //   [ [id: "sub-2"], "sub-2_t1_cropped.nii.gz" ]  ]
PREPROC_T1.out.mask_final.view()        // [ [ [id: "sub-1"], "sub-1_t1_mask_cropped.nii.gz" ],
                                        //   [ [id: "sub-2"], "sub-2_t1_mask_cropped.nii.gz" ]  ]
PREPROC_T1.out.versions.first().view()  // [ "versions.yml" ]
```


# Prototyping using components from `nf-neuro`

> [!IMPORTANT]
> First, follow the [prototyping guide](./docs/environment/PROTOTYPING.md) to setup your
> `development environment` or check if your current one meets the requirements.

## Here we can put what Anthony wrote !


# Porting prototypes to `nf-` ready pipelines

**SECTION TO COME**

# Contributing to the `nf-neuro` project

> [!IMPORTANT]
> First, follow the [devops guide](./docs/environment/DEVOPS.md) to setup your
> `development environment` or check if your current one meets the requirements.

`nf-neuro` accepts contribution of new **modules** and **subworkflows** to its library. You'll need first to
[setup your environment](./docs/DEVOPS.md), for which we have devised clever ways to streamline the procedure.
Then, depending on which kind of component you want to submit, you'll either need to follow the [module creation](./docs/MODULE.md)
or the [subworkflow creation](./docs/SUBWORKFLOWS.md) guidelines. Components that don't abide to them won't be accepted
and PR containing them will be closed automatically.

# Running tests

Tests are run through `nf-core`, using the command :

```bash
nf-core modules test <category/tool>
```

The tool can be omitted to run tests for all modules in a category.
