# Prototyping using components from `nf-neuro`

- [Prototyping using components from `nf-neuro`](#prototyping-using-components-from-nf-neuro)
  - [Environment configuration](#environment-configuration)
  - [Basic prototype pipeline creation](#basic-prototype-pipeline-creation)
    - [`main.nf`](#mainnf)
      - [`main.nf` example](#mainnf-example)
    - [`nextflow.config`](#nextflowconfig)

First and foremost, if not already done, create a directory to host your project's files and navigate to it.

```bash
mkdir -p path/to/my/project
cd path/to/my/project
```

## Environment configuration

To get setup fast, we recommend using **VS Code** and the `development container`. Follow the
[guide here](./environment/devcontainers/PROTOTYPING.md) to do so. You can also use
[those instructions](./environment/NFCORE.md#manual-installation) to setup yourself manually.

## Basic prototype pipeline creation

To create a prototype pipeline (for personal use or testing), you need first to create a few empty
files in your project's directory at the root :

```
nextflow.config
main.nf
.nf-core.yml
```

### `nextflow.config`

The `nextflow.config` file contains **parameters** that users can change when calling you pipeline
(prefixed with `params.`) and default configurations for execution. Here is an example of a basic
`nextflow.config` file :

```nextflow
params.input      = false
params.output     = 'output'

docker.enabled    = true
docker.runOptions = '-u $(id -u):$(id -g)'
```

The parameters defined with `params.` can be changed at execution by another `nextflow.config` file or
by supplying them as arguments when calling the pipeline using `nextflow run` :

```bash
nextflow run main.nf --input /path/to/input --output /path/to/output
```

### `main.nf`

This file is your pipeline execution file. It contains all modules and subworkflows you want to run, and the
channels that define how data passes between them. This is also where you define how to fetch your input files.
This can be done using a workflow definition, here is an example for a basic usage:

```nextflow
#!/usr/bin/env nextflow

workflow get_data {
    main:
        if ( !params.input ) {
            log.info "You must provide an input directory containing all images using:"
            log.info ""
            log.info "        --input=/path/to/[input]             Input directory containing your subjects"
            log.info ""
            log.info "                         [input]"
            log.info "                           ├-- S1"
            log.info "                           |   ├-- *dwi.nii.gz"
            log.info "                           |   ├-- *dwi.bval"
            log.info "                           |   ├-- *dwi.bvec"
            log.info "                           |   ├-- *revb0.nii.gz"
            log.info "                           |   └-- *t1.nii.gz"
            log.info "                           └-- S2"
            log.info "                                ├-- *dwi.nii.gz"
            log.info "                                ├-- *bval"
            log.info "                                ├-- *bvec"
            log.info "                                ├-- *revb0.nii.gz"
            log.info "                                └-- *t1.nii.gz"
            log.info ""
            error "Please resubmit your command with the previous file structure."
        }
        input = file(params.input)
        // ** Loading all files. ** //
        dwi_channel = Channel.fromFilePairs("$input/**/*dwi.{nii.gz,bval,bvec}", size: 3, flat: true)
            { it.parent.name }
            .map{ sid, bvals, bvecs, dwi -> [ [id: sid], dwi, bvals, bvecs ] } // Reordering the inputs.
        rev_channel = Channel.fromFilePairs("$input/**/*revb0.nii.gz", size: 1, flat: true)
            { it.parent.name }
            .map{ sid, rev -> [ [id: sid], rev ] }
        t1_channel = Channel.fromFilePairs("$input/**/*t1.nii.gz", size: 1, flat: true)
            { it.parent.name }
            .map{ sid, t1 -> [ [id: sid], t1 ] }
    emit:
        dwi = dwi_channel
        rev = rev_channel
        t1 = t1_channel
}

workflow {
    // ** Now call your input workflow to fetch your files ** //
    data = get_data()
    data.dwi.view() // Contains your DWI data: [meta, dwi, bval, bvec]
    data.rev.view() // Contains your reverse B0 data: [meta, rev]
    data.t1.view() // Contains your anatomical data (T1 in this case): [meta, t1]
}
```

Now, you can install the modules you want to include in your pipeline. Let's import the `denoising/nlmeans` module
for T1 denoising. To do so, first open a terminal using the **VS Code** interface, either using the main menu
`Terminal > New Terminal` or the shortcut ``ctrl+shit+` ``. Then, use the `nf-core modules install` command.

```bash
nf-core modules install denoising/nlmeans
```

> [!NOTE]
> On a first run of the commands, you may get prompted to configure some aspects of `nf-core`. You can accept every
> prompt you see.

> [!IMPORTANT]
> If you get an error telling `nf-core` command doesn't exists, then `poetry` has failed to load in the terminal
> correctly. First, close your terminal, open a new one and try again. If the tool still cannot be found, try the
> command `poetry shell`, then running `nf-core modules install` again. If this does not solve the problem, [open an
> issue](https://github.com/scilus/nf-neuro/issues/new?template=bug_report.md) on the `nf-neuro` repository.

To use it in your pipeline, you need to import it at the top of your `main.nf` file. You can do it using the
`include { DENOISING_NLMEANS } from ./modules/nf-neuro/denoising/nlmeans/main.nf` statement. Once done, you can
use `DENOISING_NLMEANS` in your pipeline and feed your inputs to it! To have a look at which files are required to
run the module, use the `nf-core modules info denoising/nlmeans` command (if you are using **VS Code**, install the
`nextflow` extension, that gives you hints on modules and subworkflows intputs). A complete example (e.g., fetching the
inputs, importing the module, and supplying the inputs to the modules) can be seen below:

#### `main.nf` example

```nextflow
#!/usr/bin/env nextflow

include { DENOISING_NLMEANS } from './modules/nf-neuro/denoising/nlmeans/main.nf'

workflow get_data {
    main:
        if ( !params.input ) {
            log.info "You must provide an input directory containing all images using:"
            log.info ""
            log.info "        --input=/path/to/[input]             Input directory containing your subjects"
            log.info ""
            log.info "                         [input]"
            log.info "                           ├-- S1"
            log.info "                           |   ├-- *dwi.nii.gz"
            log.info "                           |   ├-- *dwi.bval"
            log.info "                           |   ├-- *dwi.bvec"
            log.info "                           |   ├-- *revb0.nii.gz"
            log.info "                           |   └-- *t1.nii.gz"
            log.info "                           └-- S2"
            log.info "                                ├-- *dwi.nii.gz"
            log.info "                                ├-- *bval"
            log.info "                                ├-- *bvec"
            log.info "                                ├-- *revb0.nii.gz"
            log.info "                                └-- *t1.nii.gz"
            log.info ""
            error "Please resubmit your command with the previous file structure."
        }
        }
        input = file(params.input)
        // ** Loading all files. ** //
        dwi_channel = Channel.fromFilePairs("$input/**/*dwi.{nii.gz,bval,bvec}", size: 3, flat: true)
            { it.parent.name }
            .map{ sid, bvals, bvecs, dwi -> [ [id: sid], dwi, bvals, bvecs ] } // Reordering the inputs.
        rev_channel = Channel.fromFilePairs("$input/**/*revb0.nii.gz", size: 1, flat: true)
            { it.parent.name }
            .map{ sid, rev -> [ [id: sid], rev ] }
        anat_channel = Channel.fromFilePairs("$input/**/*t1.nii.gz", size: 1, flat: true)
            { it.parent.name }
            .map{ sid, t1 -> [ [id: sid], t1 ] }
    emit: // Those three lines below define your named output, use those labels to select which file you want.
        dwi = dwi_channel
        rev = rev_channel
        anat = anat_channel
}

workflow {
    inputs = get_data()
    // ** Create the input channel for nlmeans. ** //
    // **  - Note that it also can take a mask as input, but it is not required. ** //
    // **  - Replacing it by an empty list here. ** //
    ch_denoising = inputs.t1
        .map{ it + [[]] } // This add one empty list to the channel, since we do not have a mask.

    // ** Run DENOISING_NLMEANS ** //
    DENOISING_NLMEANS( ch_denoising )
    DENOISING_NLMEANS.out.image.view() // This will show the output of the module.

    // ** You can then reuse the outputs and supply them to another module/subworkflow! ** //
    //ch_nextmodule = DENOISING_NLMEANS.out.image
    //  .join(ch_another_file)
  // NEXT_MODULE( ch_nextmodule )
}
```

### Fetching the outputs from the modules

You now have a working `main.nf` file. You could execute the pipeline, but the outputs would be hard to access. Let's define the
`publishDir` into which to place them using the `nextflow.config` file and the `output` parameter we defined earlier :

```nextflow
process {
    publishDir = { "${params.output}/$meta.id/${task.process.replaceAll(':', '-')}" }
}
```

> [!IMPORTANT]
> Here, `meta` is a special variable, defined in every **module**, a map that gets passed around with the data, into which you can
> put information. Beware however, as it is also used to **join channels together** by looking at there whole content.

### Defining modules parameters

Once this is done, you might want to supply parameters for some of your modules that could be modified when calling the pipeline.
To know which parameters are accepted in your modules, refer to the `main.nf` of the specific `nf-neuro` module and look for parameters
that are prefixed with `ext.`, placed just before its **bash script**. `denoising/nlmeans` takes 1 possible parameter, `number_of_coils`,
that we add to the `nextflow.config` file :

```nextflow
params.number_of_coils = 1
```

The last step is to bind your parameters to the specific module they are meant for. This is done using a **process selector** (`withName`), that
links the `ext.` parameter to the `params.` parameter :

```nextflow
withName: 'DENOISING_NLMEANS' {
  ext.number_of_coils = params.number_of_coils
}
```

That's it! Your `nextflow.config` should look something like this:

```
params.input      = false
params.output     = 'output'

docker.enabled    = true
docker.runOptions = '-u $(id -u):$(id -g)'

process {
    publishDir = { "${params.output}/$meta.id/${task.process.replaceAll(':', '-')}" }
}

params.number_of_coils = 1

withName: 'DENOISING_NLMEANS' {
    ext.number_of_coils = params.number_of_coils
}
```

Once your pipeline is built, or when you want to test it, run `nextflow run main.nf --input <directory>`.
