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
            description='Convert a module\'s meta.yml file to markdown',
            formatter_class=argparse.RawTextHelpFormatter)

    p.add_argument('module_meta', help='Module meta.yml file to convert')
    p.add_argument('last_commit', help='Last commit hash of the module')
    p.add_argument('output', help='Name of the output markdown file')

    return p

def TEMPLATE(
    module_name : str,
    short_name : str,
    description : str,
    short_description : str,
    keywords : list[str],
    params : str | None,
    inputs : str,
    outputs : str,
    tools : str,
    authors : str,
    maintainers : str | None,
    last_updated : str,
    last_commit : str):

    return f"""\
---
title: {short_name}
head:
- tag: meta
  attrs:
    name: keywords
    content: {', '.join(keywords)}
- tag: meta
  attrs:
    name: description
    content: |
        {short_description}
---

## Module: {module_name}

{description}

**Keywords :** {', '.join(keywords)}

---

### Inputs

| | Type | Description | Mandatory | Pattern |
|-|------|-------------|-----------|---------|
{inputs}

### Outputs

| | Type | Description | Pattern |
|-|------|-------------|---------|
{outputs}

{f'''
### Arguments (see [process.ext](https://www.nextflow.io/docs/latest/reference/process.html#ext))
| | Type | Description | Default | Choices |
|-|------|-------------|---------|---------|
{params}
''' if params else ''}

---

### Tools

| | Description | DOI |
|-|-------------|-----|
{tools}

---

### Authors

{authors}

{'### Maintainers' if maintainers else ''}

{maintainers}

---
**Last updated** : [{last_updated}](https://github.com/scilus/nf-neuro/commit/{last_commit})
"""


def convert_module_to_md(yaml_data, commit_hash):
    # Take the module name and replace the _ by /.
    module_name = yaml_data['name'].replace("_", "/")
    # Take only the second part of the module name.
    short_name = module_name.split("/")[1]

    # Table for the tools section.
    tools = []
    for tool in yaml_data['tools']:
        name = next(iter(tool))
        description = tool[name]['description'].replace("\n", " ")
        homepage = tool[name].get('homepage', "").replace("\n", " ")
        doi = tool[name].get('doi', "").replace("\n", " ")
        tools.append(f"| [{name}]({homepage}) | {description} | [{doi}](https://doi.org/{doi}) |")

    # Table for inputs.
    inputs = []
    for input_ in yaml_data['input']:
        name = next(iter(input_))
        input_type = input_[name]['type'].replace("\n", " ")
        description = input_[name]['description'].replace("\n", " ")
        try:  # If no pattern, then set it to empty string.
            pattern = input_[name]['pattern'].replace("\n", " ")
        except KeyError:
            pattern = ""
        if name != "meta":
            try:
                mandatory = str(input_[name]['mandatory']).replace("\n", " ").lower()
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
            try:
                if isinstance(param[name]['choices'], str):
                    choices = param[name]['choices'].replace("\n", " ")
                elif isinstance(param[name]['choices'], list):
                    choices = "<br>".join(param[name]['choices']).replace("\n", " ")
            except KeyError:
                choices = ""
            default = param[name]['default']
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

    # Authors list.
    authors = []
    for author in yaml_data['authors']:
        if "@" in author:
            authors.append(f"[{author.replace('@', '')}](https://github.com/{author.replace('@', '')})")
        else:
            authors.append(author)

    # Maintainers list.
    try:
        maintainers = []
        for maintainer in yaml_data['maintainers']:
            if "@" in maintainer:
                maintainers.append(f"[{maintainer.replace('@', '')}](https://github.com/{maintainer.replace('@', '')})")
            else:
                maintainers.append(maintainer)
    except KeyError:
        maintainers = []

    short_description = yaml_data['description'].split('.')
    short_description = short_description[:min(4, len(short_description) - 1)]
    short_description = '.'.join(short_description).replace("\n", " ") + ". ..."

    return TEMPLATE(
        module_name=module_name,
        short_name=short_name,
        description=yaml_data['description'],
        short_description=short_description,
        keywords=yaml_data.get('keywords', []),
        params="\n".join(params),
        inputs="\n".join(inputs),
        outputs="\n".join(outputs),
        tools="\n".join(tools),
        authors=", ".join(authors),
        maintainers=", ".join(maintainers),
        last_updated=datetime.datetime.now().strftime("%Y-%m-%d"),
        last_commit=commit_hash
    )


def main():
    parser = _build_arg_parser()
    args = parser.parse_args()

    with open(args.module_meta, 'r') as meta:
        md_data = convert_module_to_md(yaml.safe_load(meta), args.last_commit)
        # Write the final markdown file.
        output_path = Path(args.output)
        output_path.write_text(md_data)


if __name__ == '__main__':
    main()
