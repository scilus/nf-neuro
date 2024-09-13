# Contributing to nf-neuro <!-- omit in toc -->

* [Adding a new module to nf-neuro](#adding-a-new-module-to-nf-neuro)
  * [Generate the template](#generate-the-template)
  * [Edit the template](#edit-the-template)
    * [Edit `main.nf`:](#edit-mainnf)
    * [Edit `environment.yml`:](#edit-environmentyml)
    * [Edit `meta.yml`:](#edit-metayml)
  * [Create test cases](#create-test-cases)
    * [Edit `tests/main.nf.test`:](#edit-testsmainnftest)
    * [Edit `tests/nextflow.config`:](#edit-testsnextflowconfig)
  * [Generate tests snapshots](#generate-tests-snapshots)
  * [Lint your code](#lint-your-code)
  * [Submit your PR](#submit-your-pr)
* [Defining optional input parameters](#defining-optional-input-parameters)
* [Test data infrastructure](#test-data-infrastructure)

# Adding a new module to nf-neuro

## Generate the template

First verify you are located at the root of this repository (not in `modules`), then run the following interactive command :

```bash
nf-core modules create
```

You will be prompted several times to configure the new module correctly. Refer
to the following to ensure configuration abides with `nf-neuro` :

- **Name of tool/subtool** : `category/tool` of the module you plan creating (e.g. denoising/nlmeans).
- **Bioconda package** : select `no`.
- **Github author** : use your Github handle, or `@scilus` if you prefer not being identified through nf-neuro.
- **Resource label** : select `process_single` for now, for any tool (multiprocessing and acceleration will be delt with later).
- **Meta map** : select `yes`.

Alternatively, you can use the following command to supply nearly all information :

```bash
nf-core modules create --author @scilus --label process_single --meta <category>/<tool>
```

You will still have to interact with the **bioconda** prompt, still select `no`.

> [!NOTE]
> Once used to the conventions, adding `--empty-template` to the command will disable
> auto-generation of comments, examples and TODOs and can be a time-saver.

The command will generate a new module template in the `./modules/nf-neuro/<category>/<tool>` directory.

## Edit the template

The template has to be edited in order to work with `nf-neuro` and still be importable
through `nf-core`. Refer to the `betcrop/fslbetcrop` module for an example as it should
already follow all guidelines. You will find related files in :

- `modules/nf-neuro/betcrop/fslbetcrop`
- `tests/modules/nf-neuro/betcrop/fslbetcrop`

### Edit `main.nf`:

- Remove the line `conda "YOUR-TOOL-HERE"`.

- If the process uses the `scilus` container, use the following replacements,
  else remove the whole section.

  `depot.galaxyproject.org...` &DoubleLongRightArrow; `https://scil.usherbrooke.ca/containers/scilus_1.6.0.sif`

  `biocontainers/YOUR-TOOL-HERE` &DoubleLongRightArrow; `scilus/scilus:1.6.0`

- Add your inputs in the `input:` section :

  > Each line below `input:` defines an input channel for the process. A channel can
  > receive one (`val`, `path`, ...) or more (`tuple`) values per item.

  > When possible, add all optional input parameters (not data !) to `task.ext` instead of
  > listing them in the `input:` section (see [this section](#defining-processes-optional-parameters)
  > for more information).

  - All inputs are assumed to be `required` by default.

  - If an input is scoped to a subject, the line MUST start with `tuple val(meta), `.

  - An input `path` CAN be optional (though it is not officially supported). You simply
    have to pass it an empty list `[]` for Nextflow to consider its value empty, but
    correct.

    > If you decide an input `path` value is optional, add `/* optional, value = [] */`
    > aside the parameter (e.g. f1 is optional, so `path(f1) /* optional, value = [] */`
    > or even `tuple val(meta), path(f1) /* optional, value = [] */, path(...` are valid
    > syntaxes). This will make input lines long, but they will be detectable. When we
    > can define input tuples on multiple lines, we'll deal with this.

    In the script section, before the script definition (in `""" """`), unpack the
    optional argument into a `usable variable`. For a optional input `input1`, add :

    ```groovy
    def optional_input1 = input1 ? "<unpack input1>" : "<default if input1 unusable>"
    ```

    The variable `optional_input1` is the one to use in the script.

    > At its most simple, a variable is `usable` if its conversion to a string is valid
    > in the script (e.g. : if a variable can be empty or null, then its conversion to an
    > empty string must be valid in the sense of the script for the variable to be considered
    > `usable`).

- Add all outputs in the `output` section :

  - As for inputs, each line defines an output channel. If an output is scoped to a
    subject, the line MUST start with `tuple val(meta), `.

  - File extensions MUST ALWAYS be defined (e.g. `path("*.{nii,nii.gz}")`).

  > Each line MUST use `emit: <name>` to make its results available inside Nextflow using
  > a relevant `name`. Results are accessible using : `PROCESS_NAME.out.<name>`.

  > Optional outputs ARE possible, add `, optional: true` after the `emit: <name>` clause.

- Fill the `script` section :

  - Use the `prefix` variable to name the scoped output files. If needed, modify the
    variable definition in the groovy pre-script.

  - Define dependencies versions :

    In the versioning section at the bottom of the script :

    ```bash
    cat <<-END_VERSIONS > versions.yml
      "${task.process}":
        <your dependencies>
    END_VERSIONS
    ```

    remove the lines in between the `cat` and the `END_VERSIONS` line. In it, add
    for each dependency a new line in the format : `<name>: <version>`.

    > You can hard-bake the version as a number here, but if possible extract if from
    > the dependency dynamically. Refer to the `betcrop/fslbetcrop` module, in `main.nf`
    > for examples on how to extract the version number correctly.

- Fill the `stub` section :

  Using the same conventions as for the `script` section, define a simple test stub :

  - Call the helps of all scripts used, if possible.

  - Call `touch <file>` to generate empty files for all required outputs.

### Edit `environment.yml`:

Start by removing the comments added automatically by `nf-core`, then, replace the existing `channels` section by:

```yml
channels:
  - Docker
  - Apptainer
```

and add the name of the tools used within your module in the `dependencies` section. For example, if you are using `scilpy` tools, write:

```yml
dependencies:
  - scilpy
```

### Edit `meta.yml`:

Fill the sections you find relevant. There is a lot of metadata in this file, but we
don't need to specify them all. At least define the `keywords`, describe the process'
`inputs` and `outputs`, and add a `short documentation` for the tool(s) used in the process. The types allowed for the `inputs` and `outputs` are : `map`, `list`, `file`, `directory`, `string`, `integer`, `float` and `boolean`.

> [!IMPORTANT]
> The `tool` documentation does not describe your module, but to the tools you use in
> the module ! If you use scripts from `scilpy`, here you describe scilpy. If using
> `ANTs`, describe ANts. Etcetera.

Once done, commit your module and push the changes. Then, to look at the documentation it creates for your module, run :

```bash
nf-core modules info <category/name>
```

## Create test cases

The module's test infrastructure is auto-generated when creating a module using the `nf-core` command. First file you should modify is the `main.nf.test`, which contains the input and assertion instructions for `nf-test`.

> [!NOTE]
> Multiple tests can be specified one after the other in the `main.nf.test`, be sure to corner most of the use-case of your module to ensure catching any potential bugs!

### Edit `tests/main.nf.test`:

To specify test data, you need to define a `setup` section before the actual test definition. This setup section will use the `LOAD_TEST_DATA` workflow to fetch your test data from an available package (refer to [this section](#test-data-infrastructure) to learn how to find packages). Once you selected the archives and files you need, add a `setup` section before the test section.

```groovy
setup {
  run("LOAD_TEST_DATA", alias: "LOAD_DATA") {
    script "../../../../../subworkflows/nf-neuro/load_test_data/main.nf"
    process {
      """
      input[0] = Channel.from( [ "<archive>" ] )
      input[1] = "test.load-test-data"
      """
    }
  }
}
```

Replace the `<archive>` with the name of the one you need and you'll be able to access the archives within your test suite! Next, you want to define your inputs for your actual tests. The inputs are defined in a positional order, meaning that `input[0]` will be the first one provided to your process. Every `input[i]` represents a channel, so if your process takes, for example, a `tuple val(meta), path(image)`, you will have to define the meta and image within the same `input[i]`. A code block for a test that takes this tuple as input would look like this:

```groovy
    test("example - simple") {
        config "./nextflow.config"
        when {
            process {
                """
                input[0] = LOAD_DATA.out.test_data_directory.map{
                    test_data_directory -> [
                        [ id:'test', single_end:false ], // meta map    -> your meta
                        file("\${test_data_directory}/image.nii.gz") // -> your image file.
                    ]
                }
                """
            }
        }
        then {
            assertAll(
                { assert process.success },
                { assert snapshot(process.out).match() }
            )
        }
    }
```

If your process takes an optional input (such as a mask), you can simply add an empty list:

```groovy
  """
  input[0] = LOAD_DATA.out.test_data_directory.map{
      test_data_directory -> [
          [ id:'test', single_end:false ], // meta map      -> your meta
          file("\${test_data_directory}/image.nii.gz"), //  -> your image file.
          []                                            //  -> your optional input.
      ]
  }
  """
```

Once you have set up your input correctly, you need to define, in the `then` section, the assertions to carry on the files and variables the module's outputs. The `snapshot` function usually takes care of correctly resuming the data it receives into `md5sums` and most times giving it `process.out` is enough.

```groovy
then {
    assertAll(
        { assert process.success },
        { assert snapshot(process.out).match() }
    )
}
```

However, it is not the case right now for `Nifti` images, which require the use of a dedicated method to extract a reproducible `md5sum`, aka `Nifti_md5sum`. To assert a `Nifti` output, in this example case the first one, do the following :

```groovy
then {
    assertAll(
        { assert process.success },
        { assert snapshot(
          Nifti_md5sum(process.out.get(0).get(1)),
          ...
          ).match()
        }
    )
}
```

Here we consider all outputs are `tuples`, with the first field being the `meta` dictionary associated to it. For more details regarding the possible assertions, see the [nf-test doc](https://www.nf-test.com/docs/assertions/assertions/).

To add more test cases, you can add multiple `test` sections as defined above (all within the same `nextflow process {}`). This can be done to test with different inputs, or different parameters provided through a `nextflow.config` file. If you want to define specific parameters for a single test, assign the `nextflow.config` file using the `config` parameter within the test definition (as shown above). If you want to assign identical parameters for all tests, you can bind the `nextflow.config` file at the beginning of the `main.nf.test`:

```groovy
nextflow_process {

    name "Test Process <CATEGORY>_<TOOL>"
    script "../main.nf"
    process "<CATEGORY>_<TOOL>"
    config "./nextflow.config"
```

Finally, ensure all the tags at the beginning of the process definition include the `LOAD_TEST_DATA` subworkflow. If not, add those two lines:

```groovy
    tag "subworkflows"
    tag "subworkflows/load_test_data"
```

Make sure there is no more comments generated by the `nf-core` template, and you should be good to go!

### Edit `tests/nextflow.config`:

The `nextflow.config` file does not exist by default, so you will have to create it if needed. This is not mandatory, except if you have defined optional parameters with `task.ext` and want to alter their values for some test cases. Refer to [this section](#defining-optional-input-parameters) to
see how to scope those parameters to specific tests using `selectors`.

## Generate tests snapshots

> [!WARNING]
> Verify you are located at the root of `nf-neuro` (not inside modules) before
> running commands !

Once you have correctly setup your test cases and made sure the data is available, the test module has to be pre-tested
so output files that gets generated are snapshotted correctly before being pushed to `nf-neuro`.

To do so, run:

```bash
nf-core modules test -u <category>/<tool>
```

All the test case you defined will be run, watch out for errors ! Once everything runs
smoothly, look at the snapshot file produced at `tests/main.nf.test.snap` in your module's 
directory and validate that ALL outputs produced by test cases are caught. Their `md5sum` is
critical to ensure future executions of your test produce valid outputs.

## Lint your code

Before submitting to _nf-neuro_, once you've commit and push everything, the code need to be correctly linted, else the checks won't pass. This is done using `prettier` on your new module, through the _nf-core_ command line :

```bash
nf-core modules lint <category>/<tool>
```

You'll probably get a bunch of _whitespace_ and _indentation_ errors, but also image errors, bad _nextflow_ syntax and more. You need to fix all `errors` and as much as the `warnings`as possible.

## Submit your PR

Open a PR to the `nf-neuro` repository master. We'll test everything, make sure it's
working and that code follows standards.

> [!NOTE]
> It's the perfect place to get new tools added to our containers, if need be !

Once LGTM has been declared, wave to the maintainers and look at your hard work paying off.

PR merged !

# Defining optional input parameters

Using the DLS2 module framework, we can define passage of optional parameters using a configuration
proprietary to the `process scope`, the `task.ext` mapping (or dictionary). In `nf-core`, the convention
is to load `task.ext.args` with all optional parameters acceptable by the process.

This does not work perfectly for our use-cases, and instead, we use the whole `task.ext` as a
parameters map. To define an optional parameter `param1` through `task.ext`, add the following to
the process script section, before the script definition (in `""" """`) :

```groovy
def args_for_cmd1 = task.ext.param1 ? "<parameter flag for param1 if needed> $task.ext.param1"
                                    : '<empty string or what to do if not supplied>'
```

Then, use `args_for_cmd1` in the script. Defining the actual value for the parameters is done
by means of `.config` files, inside the `process` scope. A global affectation of the parameter
is as simple as :

```groovy
process {
  task.ext.param1 = "<my global value>"
}
```

Doing so will affect **ALL** processes. To scope to a specific process, use the
[process selectors](https://www.nextflow.io/docs/latest/config.html#process-selectors)
(`withName:` or `withLabel:`) :

```groovy
process {
  withName: "PROCESS1" {
    task.ext.param1 = "<scoped to PROCESS1 value>"
  }
}
```

You can define the selector on multiple levels and use glob matching, making it so that
it is possible to affect the processes inside a specific workflow as well :

```groovy
process {
  withName: "WORKFLOW_X*" {
    task.ext.param1 = "<scoped to processes in WORKFLOW_X value>"
  }
}
```

> [!IMPORTANT]
> Modules inherit **selectors**. Thus, a module renamed at import (`import {A as B}`)
> will be affected both by the selection `withName: "A"` and `withName: "B"`. However,
> parameters defined by `B` will have precedence on those define in `A`.

> [!IMPORTANT]
> The same stands for **selectors** defined on multiple levels, implicit (`withName: WORKFLOW_X*`)
> or explicit (`withName: WORKFLOW_Y:B`).

# Test data infrastructure

`nf-neuro` provides an infrastructure to host and distribute test data, freely available to all
contributors. Access to this data is done through the dedicated subworkflow `LOAD_TEST_DATA`. Test
data packages are listed in `tests/config/test_data.json`. Introspection of their content is
available in VS Code only, using the [Test Data Explorer](https://marketplace.visualstudio.com/items?itemName=nf-neuro.test-data-explorer)
extension. Once installed, it adds the `Test Data Explorer` to the explorer panel (`Ctrl+Shift+E`),
which you can use to browse and download test data packages and their content.

To download test data inside your test workflows, first include the `LOAD_TEST_DATA` workflow
in their `main.nf` :

```groovy
include { LOAD_TEST_DATA } from '../../../../../subworkflows/nf-neuro/load_test_data/main'
```

The workflow has two inputs :

- A channel containing a list of package names to download.

- A name for the temporary directory where the data will be put.

To call it, use the following syntax :

```groovy
archives = Channel.from( [ "<archive1>", "archive2", ... ] )
LOAD_TEST_DATA( archives, "<directory>" )
```

> [!IMPORTANT]
> This will download the `archives` and unpack them under the `directory`
> specified, using the archive's names as `sub-directories` to unpack to.

The archives contents are accessed using the output parameter of the workflow
`LOAD_TEST_DATA.out.test_data_directory`. To create the test input from it for
a given `PROCESS` to test use the `.map` operator :

```groovy
input = LOAD_TEST_DATA.out.test_data_directory
  .map{ test_data_directory -> [
    [ id:'test', single_end:false ], // meta map
    file("${test_data_directory}/<file for input 1>"),
    file("${test_data_directory}/<file for input 2>"),
    ...
  ] }
```

Then feed it to it :

```groovy
PROCESS( input )
```

> [!NOTE]
> The subworkflow must be called individually in each test workflow, even if they download
> the same archives, since there is no mechanism to pass data channels to them from the
> outside. Nevertheless, downloaded archives are cached locally to ensure efficiency and
> preserve bandwidth.
