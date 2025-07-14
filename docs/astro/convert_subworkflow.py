#! /usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Python script to convert a YAML file to a markdown file.

Inspired by:
https://github.com/mskcc-omics-workflows/yaml_to_md/blob/main/yaml_to_md.py
"""

import argparse
import yaml
import datetime

from pathlib import Path


def read_yml(yml_file):
    """
    Small function to read yml file.
    """
    return yml_file.read_text()


def _build_arg_parser():
    p = argparse.ArgumentParser(
            description='Convert subworkflows YAML to Markdown files',
            formatter_class=argparse.RawTextHelpFormatter)

    p.add_argument('subworkflow_meta', help='Subworkflow meta.yml file to convert')
    p.add_argument('last_commit', help='Last commit hash of the subworkflow')
    p.add_argument('output', help='Name of the output markdown file')

    return p


def TEMPLATE(
    subworkflow_name,
    description,
    keywords,
    params,
    inputs,
    outputs,
    components,
    authors,
    maintainers,
    last_updated,
    last_commit):

    return f"""\
---
title: {subworkflow_name}
head:
- tag: meta
attrs:
    name: keywords
    content: {', '.join(keywords)}
- tag: meta
attrs:
    name: description
    content: |
        {description}
---

## Subworkflow: {subworkflow_name}

{description}

**Keywords :** {', '.join(keywords)}

---

{f'''
### Inputs

| | Type | Description | Mandatory | Pattern |
|-|------|-------------|-----------|---------|
{inputs}
''' if inputs else ''}

{f'''
### Outputs

| | Type | Description | Pattern |
|-|------|-------------|---------|
{outputs}
''' if outputs else ''}

{f'''
### Parameters (see [parameters](https://www.nextflow.io/docs/latest/config.html#parameters))
| | Type | Description | Default | Choices |
|-|------|-------------|---------|---------|
{params}
''' if params else ''}

---

{f'''
### Components

{components}
''' if components else ''}

---

### Authors

{authors}

{'### Maintainers' if any(maintainers) else ''}

{maintainers}

---
**Last updated** : [{last_updated}](https://github.com/scilus/nf-neuro/commit/{last_commit})
"""


def convert_subworkflow_to_md(yaml_data, commit_hash):
    # Table for inputs.
    inputs = []
    for input in yaml_data['input']:
        name = next(iter(input))
        input_type = input[name]['type'].replace("\n", " ")
        description = input[name]['description'].replace("\n", " ")
        try:  # If no pattern, then set it to empty string.
            pattern = input[name]['pattern'].replace("\n", " ")
        except KeyError:
            pattern = ""
        if name != "meta":
            try:  # If no default, then set it to empty string.
                mandatory = str(input[name]['mandatory']).replace("\n", " ").lower()
            except KeyError:
                mandatory = ""
        else:
            mandatory = "true"

        inputs.append(f"| {name} | {input_type} | {description} | {mandatory} | {pattern} |")

    # Table for params.
    try:
        params = []
        for param in yaml_data['args']:
            name = next(iter(param))
            param_type = param[name]['type'].replace("\n", " ")
            description = param[name]['description'].replace("\n", " ")
            default = param[name]['default']
            try:  # If no choices, then set it to empty string.
                if isinstance(param[name]['choices'], str):
                    choices = param[name]['choices'].replace("\n", " ")
                else:
                    choices = ", ".join(param[name]['choices']).replace("\n", " ")
            except KeyError:
                choices = ""
            params.append(f"| {name} | {param_type} | {description} | {default} | {choices} |")
    except KeyError:
        params = ""

    # Table for outputs.
    outputs = []
    for output in yaml_data['output']:
        name = next(iter(output))
        output_type = output[name]['type'].replace("\n", " ")
        description = output[name]['description'].replace("\n", " ")
        try:  # If no pattern, then set it to empty string.
            pattern = output[name]['pattern'].replace("\n", " ")
        except KeyError:
            pattern = ""
        outputs.append(f"| {name} | {output_type} | {description} | {pattern} |")

    # Components list
    components = []
    for component in yaml_data.get('components', []):
        if "/" in component:
            components.append(f"- [{component}](https://scilus.github.io/nf-neuro/api/modules/{component})")
        else:
            components.append(f"- [{component}](https://scilus.github.io/nf-neuro/api/subworkflows/{component})")

    return TEMPLATE(
        subworkflow_name=yaml_data['name'],
        description=yaml_data['description'],
        keywords=yaml_data.get('keywords', []),
        params="\n".join(params),
        inputs="\n".join(inputs),
        outputs="\n".join(outputs),
        components="\n".join(components),
        authors=", ".join(yaml_data['authors']),
        maintainers=", ".join(yaml_data.get('maintainers', [])),
        last_updated=datetime.datetime.now().strftime("%Y-%m-%d"),
        last_commit=commit_hash
    )


def main():
    parser = _build_arg_parser()
    args = parser.parse_args()

    with open(args.subworkflow_meta, 'r') as meta:
        md_data = convert_subworkflow_to_md(yaml.safe_load(meta), args.last_commit)
        # Write the final markdown file.
        output_path = Path(args.output)
        output_path.write_text(md_data)


if __name__ == '__main__':
    main()
