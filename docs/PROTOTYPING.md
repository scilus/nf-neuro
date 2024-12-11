# Prototyping using components from `nf-neuro`

> [!IMPORTANT]
> First, follow the [prototyping guide](./docs/environment/PROTOTYPING.md) to setup your
> `development environment` or check if your current one meets the requirements.

* [Prototyping using components from `nf-neuro`](#prototyping-using-components-from-nf-neuro)
  * [Basic prototype pipeline creation](#basic-prototype-pipeline-creation)
    * [`main.nf`](#mainnf)
      * [`main.nf` example](#mainnf-example)
    * [`nextflow.config`](#nextflowconfig)


## Basic prototype pipeline creation

To create a prototype pipeline (for personal use or testing), you will need to create a couple of files in addition to the `nf-neuro` modules/subworkflows. First, create those files at the root of your pipeline:
```
nextflow.config
main.nf
```
The `nextflow.config` file will contain your parameters for your pipeline execution that can be supplied as arguments when calling the pipeline (ex: `nextflow run main.nf --argument1 true`). The `main.nf` file will contain your pipeline. Let's take a look at this one first.

### `main.nf`

As mentioned above, this file will be your main pipeline execution file, containing all the modules/subworkflows you want to run, and the channel definition between them. This is also where you will fetch your input files. This can be done using a workflow definition, here is an example for a basic usage:

```nextflow
workflow get_data {
    main:
        if ( !params.input ) {
            log.info "You must provide an input folder containing all images using:"
            log.info "        --input=/path/to/[input_folder]             Input folder containing multiple subjects for tracking"
            log.info ""
            log.info "                               [Input]"
            log.info "                               ├-- S1"
            log.info "                               |   ├-- *dwi.nii.gz"
            log.info "                               |   ├-- *dwi.bval"
            log.info "                               |   ├-- *dwi.bvec"
            log.info "                               |   ├-- *revb0.nii.gz"
            log.info "                               |   └-- *t1.nii.gz"
            log.info "                               └-- S2"
            log.info "                                    ├-- *dwi.nii.gz"
            log.info "                                    ├-- *bval"
            log.info "                                    ├-- *bvec"
            log.info "                                    ├-- *revb0.nii.gz"
            log.info "                                    └-- *t1.nii.gz"
            error "Please resubmit your command with the previous file structure."
        }
        input = file(params.input)
        // ** Loading all files. ** //
        dwi_channel = Channel.fromFilePairs("$input/**/*dwi.{nii.gz,bval,bvec}", size: 3, flat: true)
            { it.parent.name }
            .map{ sid, bvals, bvecs, dwi -> tuple(meta.id: sid, dwi, bvals, bvecs) } // Reordering the inputs.
        rev_channel = Channel.fromFilePairs("$input/**/*revb0.nii.gz", size: 1, flat: true)
            { it.parent.name }
            .map{ sid, rev -> tuple(meta.id: sid, rev) }
        t1_channel = Channel.fromFilePairs("$input/**/*t1.nii.gz", size: 1, flat: true)
            { it.parent.name }
            .map{ sid, t1 -> tuple(meta.id: sid, t1) }
    emit:
        dwi = dwi_channel
        rev = rev_channel
        t1 = t1_channel
}
// ** Now call your input workflow to fetch your files ** //
data = get_data()
data.dwi.view() // Contains your DWI data: [meta, [dwi, bval, bvec]]
data.rev.view() // Contains your reverse B0 data: [meta, [rev]]
data.t1.view() // Contains your anatomical data (T1 in this case): [meta, [t1]]
```

Now, you can install the modules you want to include in your pipeline. Let's import the `denoising/nlmeans` module for T1 denoising. To do so, simply install it using the `nf-core modules install` command.
```bash
nf-core modules install denoising/nlmeans
```
To use it in your pipeline, you need to import it at the top of your `main.nf` file. You can do it using the `include { YOUR_NAME } from ../path/main.nf` statement. Then, you can add it to your pipeline and feed your inputs to it! To have a look at which files are required to run the module, use the `nf-core modules info <your/module>` command. A complete example (e.g., fetching the inputs, importing the module, and supplying the inputs to the modules) can be seen below:
#### `main.nf` example
```nextflow
include { DENOISING_NLMEANS } from './modules/nf-neuro/denoising/nlmeans/main.nf'
workflow get_data {
    main:
        if ( !params.input ) {
            log.info "You must provide an input folder containing all images using:"
            log.info "        --input=/path/to/[input_folder]             Input folder containing multiple subjects for tracking"
            log.info ""
            log.info "                               [Input]"
            log.info "                               ├-- S1"
            log.info "                               |   ├-- *dwi.nii.gz"
            log.info "                               |   ├-- *dwi.bval"
            log.info "                               |   ├-- *dwi.bvec"
            log.info "                               |   ├-- *revb0.nii.gz"
            log.info "                               |   └-- *t1.nii.gz"
            log.info "                               └-- S2"
            log.info "                                    ├-- *dwi.nii.gz"
            log.info "                                    ├-- *bval"
            log.info "                                    ├-- *bvec"
            log.info "                                    ├-- *revb0.nii.gz"
            log.info "                                    └-- *t1.nii.gz"
            error "Please resubmit your command with the previous file structure."
        }
        input = file(params.input)
        // ** Loading all files. ** //
        dwi_channel = Channel.fromFilePairs("$input/**/*dwi.{nii.gz,bval,bvec}", size: 3, flat: true)
            { it.parent.name }
            .map{ sid, bvals, bvecs, dwi -> tuple(meta.id: sid, dwi, bvals, bvecs) } // Reordering the inputs.
        rev_channel = Channel.fromFilePairs("$input/**/*revb0.nii.gz", size: 1, flat: true)
            { it.parent.name }
        anat_channel = Channel.fromFilePairs("$input/**/*t1.nii.gz", size: 1, flat: true)
            { it.parent.name }
    emit: // Those three lines below define your named output, use those labels to select which file you want.
        dwi = dwi_channel
        rev = rev_channel
        anat = anat_channel
}
inputs = get_data()
// ** Create the input channel for nlmeans. Note that it also can take a mask as input, but it is not required, replacing it by an empty list here. ** //
ch_denoising = inputs.t1
  .map{ it + [[]] } // This add one empty list to the channel, since we do not have a mask.
// ** Run DENOISING_NLMEANS ** //
DENOISING_NLMEANS( ch_denoising )
// ** You can then reuse the outputs and supply them to another module/subworkflow! ** //
ch_nextmodule = DENOISING_NLMEANS.out.image
  .join(ch_another_file)
NEXT_MODULE( ch_nextmodule )
```

### `nextflow.config`

You now have a working `main.nf` file, but you did not specified any parameters to your pipeline yet. Let's do this using the `nextflow.config` file. First, you will want to define your publish directory options (where your files will be outputted). You can add those lines to the beginning of your `nextflow.config`:
```nextflow
process {
  publishDir = {"${params.output_dir}/$meta.id/${task.process.replaceAll(':', '-')}"}
}
```

Once this is done, you might want to supply parameters for some of your modules that could be modified when calling the pipeline, you can add them under the `params` flag. To know which parameters are accepted in your modules, refer to the `main.nf` of the specific `nf-neuro` module. `denoising/nlmeans` takes 1 possible parameter: `number_of_coils`. By defining it as below, we will be able to modify its value during the pipeline call using `--number_of_coils 1`.
```nextflow
params{
  input = false // This will be used to supply your input directory, using --input folder/
  // ** Denoising nlmeans parameters ** //
  number_of_coils = 1
}
```
The last step is to bind your parameters to the specific module they are meant for. This can be done by explicitly stating the modules, and attaching the parameters to the appropriate `task.ext`. To do this, add those lines for each of your modules in your `nextflow.config`:
```nextflow
withName: 'DENOISING_NLMEANS' {
  ext.number_of_coils = params.number_of_coils
}
```

That's it! Your `nextflow.config` should look something like this:
```
process {
  publishDir = {"${params.output_dir}/$sid/${task.process.replaceAll(':', '-')}"}
}
params{
  input = false // This will be used to supply your input directory, using --input folder/
  // ** Denoising nlmeans parameters ** //
  number_of_coils = 1
}
withName: 'DENOISING_NLMEANS' {
  ext.number_of_coils = params.number_of_coils
}
```

Once your pipeline is built, or when you want to test it, run `nextflow run main.nf --input <folder> --param1 true --param2 4 ...`.
