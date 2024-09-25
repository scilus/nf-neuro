# Contributing to nf-neuro <!-- omit in toc -->

- [Adding a new subworkflow to nf-neuro](#adding-a-new-subworkflow-to-nf-neuro)
  - [Generate the template](#generate-the-template)
  - [Edit the template](#edit-the-template)
    - [Edit `main.nf`](#edit-mainnf)
      - [Define your subworkflow inputs](#define-your-subworkflow-inputs)
      - [Fill the `main:` section](#fill-the-main-section)
      - [Define your Workflow outputs](#define-your-workflow-outputs)
    - [Edit `meta.yml`](#edit-metayml)
    - [Create test cases](#create-test-cases)
  - [Lint your code](#lint-your-code)
  - [Submit your PR](#submit-your-pr)

# Adding a new subworkflow to nf-neuro

## Generate the template

First verify you are located at the root of this repository (not in `subworkflows`), then run the following interactive command :

```
nf-core subworkflows create
```

It will ask you to give a name for your subworkflow and an author name (use your github username).
Alternatively, you can use the following command to supply directly those informations :

```
nf-core subworkflows create <name> --author <author>
```

The command will generate a new subworkflow template in the `./subworkflows/nf-neuro/<name_of_your_workflow>` directory.

## Edit the template

### Edit `main.nf`

You can't select an empty template when you generate a new subworkflow, so the template is based on nf-core. You will need to replace some of their sections for your use case:

- Remove the different comment lines.
- Include your modules into your subworkflows (a subworkflow should include at least **two** modules). Remove the modules `{ SAMTOOLS_SORT}` and `{ SAMTOOLS_INDEX }` then includes yours with the good pathway:

```
include { <MODULES>	} from '../../../modules/nf-neuro/<category>/<tool>/main'
```

> [!NOTE]
> You can also include other subworkflows :
>
> ```
> include { <SUBWORKFLOW> } from '../<subworkflow>/main'
> ```

#### Define your subworkflow inputs

A workflow can declare one or more input channels using the `take` keyword. If some of your input channels are optional, add an optional tag after the channel specification.
Multiple inputs must be specified on separate lines:

```
take:
    channel_data1  // channel: [ val(meta), [ data1 ] ]
    channel_data2  // channel: [ val(meta), [ data2 ] ], optional
```

> [!NOTE]
> When the `take` keyword is used, the beginning of the workflow body must be defined with the `main` keyword !

#### Fill the `main:` section

Compose your workflow using the different modules and workflows you've included above.
For inputs channels, use it as follows:

```
<MODULE1> (channel_data1)
```

To connect two modules together, you need to create a channel which takes one of the outputs of the first module and feeds it to the other. To do this, use the `.out` attribute and select the desired output by name :

```
channel_module2 = <MODULE1>.out.<output>
<MODULE2> (channel_module2)
```

To assemble the outputs of one or multiple modules together in a new channel, use the [join](https://www.nextflow.io/docs/latest/operator.html#join), [combine](https://www.nextflow.io/docs/latest/operator.html#combine) and [groupTuple](https://www.nextflow.io/docs/latest/operator.html#grouptuple) operators. For example :

```
channel_module3 = <MODULE2>.out.<output>.join(channel_data1).join(channel_data2)
<MODULE3> (channel_module3)
```

> [!NOTE]
> There are different types of operator depending on your needs. For a complete list, please refer to the nextflow documentation: : https://www.nextflow.io/docs/latest/operator.html#

> [!WARNING]
> The same applies to workflows, you can link modules to workflows and vice versa.

To select a subset of values emitted by a channel (e.g. a channel emits tuples of the shape `[meta, out1, out2, out3]`, `out2` and `out3` are desired but not `out1`), use the `map` operator, for example :

```
channel_subset = channel_data.map{ meta, out1, out2, out3 -> [meta, out2, out3] }
```

For validation, you need to collect the version files of the modules and subworkflows included in yours. The first thing to do in the main is to create an empty channel:

```
ch_versions = Channel.empty()
```

Then, after each module call, add its version file into the channel:

```
channel_module2 = <MODULE1>.out.<output>
<MODULE2> (channel_module2)
ch_versions = ch_versions.mix(<MODULE2>.out.versions.first())
```

#### Define your Workflow outputs

Once the `main` finished you can define the output that you want from the different modules or workflows, be sure to assign just one output per channel. Please list as many outputs as possible for your workflow, so that it can be better reused and adapted.

A workflow can declare one or more output channels using the `emit` keyword.

```
emit:
    output1 = <MODULE1>.out.<output> // channel: [ val(meta), [ output ] ]
    output2 = <MODULE2>.out.<output> // channel: [ val(meta), [ output ] ]
```

> [!NOTE]
> As with `main`, you can create outputs containing several files using operators.

Don't forget to also define the output for the version file :

```
versions = ch_versions // channel: [ versions.yml ]
```

### Edit `meta.yml`

Fill the sections you find relevant. There is a lot of metadata in this file, but you
don't need to specify them all. Provide at least 3 relevant `keywords` and list all modules and subworkflows used in the `components` section. List all `inputs` and `outputs` in the order in which you defined them. Give a complete `description` of the subworkflow, describing all potential uses and variations of inputs and their effects on expected outputs.

### Create test cases

Adding tests to your subworkflow is near identical to modules. For detailed instructions, please see [here](./MODULE.md#create-test-cases).

> [!IMPORTANT]
> Take attention to the `wording` ! As the section refers to `modules` and `process`, carefully
> replace them with `subworkflow`, since both concepts boil down to this single descriptor in this
> specific case.

## Lint your code

Run `prettier` on your new module, through the `nf-core` command line :

```
nf-core subworkflows lint <subworkflow>
```

and fix all `errors` and as many `warnings` as possible. If at any point you modified files outside of your module's directory, those also need to be linted. To do so, run the following commands at the root of the repository :

```bash
prettier --check .
editorconfig-checker
```

You'll get lists of syntax errors to fix from both commands. For prettier, you can run `prettier --write .` to fix most of them automatically. For `editorconfig-checker`, you'll have to fix them manually.

## Submit your PR

Open a PR to the nf-neuro repository `main` branch. We'll test everything, make sure it's
working and that code follows standards.

Once LGTM has been declared, wave to the maintainers and look at your hard work paying off.

PR merged !
