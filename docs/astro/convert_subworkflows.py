#! /usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Python script to convert a YAML file to a markdown file.

Inspired by:
https://github.com/mskcc-omics-workflows/yaml_to_md/blob/main/yaml_to_md.py
"""

import argparse
import yaml

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

    p.add_argument('subworkflows_dir', help='Path to the subworkflows directory')
    p.add_argument('output_dir', help='Path to output the Markdown files')

    return p


def convert_subworkflow_to_md(yaml_data):
    # Order:
    # Inputs
    # Params
    # outputs
    # Tools
    # Keywords

    # Create a table for the Keywords section.
    keywords = "|  |\n"
    keywords += "|----------|\n"
    for keyword in yaml_data['keywords']:
        keywords += f"| {keyword} |\n"

    # Table for the components section.
    components = "|  |\n"
    components += "|----------|\n"
    for component in yaml_data['components']:
        components += f"| {component} |\n"

    # Table for inputs.
    inputs = "|  | Type | Description | Pattern |\n"
    inputs += "|-------|------|-------------|---------|\n"
    for input in yaml_data['input']:
        name = next(iter(input))
        input_type = input[name]['type'].replace("\n", " ")
        description = input[name]['description'].replace("\n", " ")
        try:  # If no pattern, then set it to empty string.
            pattern = input[name]['pattern'].replace("\n", " ")
        except KeyError:
            pattern = ""
        inputs += f"| {name} | {input_type} | {description} | {pattern} |\n"

    # Table for params.
    try:
        params = "|  | Type | Description | Default |\n"
        params += "|-------|------|-------------|---------|\n"
        for param in yaml_data['parameters']:
            name = next(iter(param))
            param_type = param[name]['type'].replace("\n", " ")
            description = param[name]['description'].replace("\n", " ")
            default = param[name]['default']
            params += f"| {name} | {param_type} | {description} | {default} |\n"
    except KeyError:
        params = ""

    # Table for outputs.
    outputs = "|  | Type | Description | Pattern |\n"
    outputs += "|--------|------|-------------|---------|\n"
    for output in yaml_data['output']:
        name = next(iter(output))
        output_type = output[name]['type'].replace("\n", " ")
        description = output[name]['description'].replace("\n", " ")
        try:  # If no pattern, then set it to empty string.
            pattern = output[name]['pattern'].replace("\n", " ")
        except KeyError:
            pattern = ""
        outputs += f"| {name} | {output_type} | {description} | {pattern} |\n"

    # Markdown file needs a frontmatter for astro to read properly.
    final_md = "---\n"
    final_md += f"title: {yaml_data['name']}\n"
    final_md += "---\n\n"

    final_md += f"## Subworkflow: {yaml_data['name']}\n\n{yaml_data['description']}\n\n"
    final_md += f"### Inputs\n\n{inputs}\n"
    if params != "":
        final_md += f"### Parameters\n\n{params}\n"
    final_md += f"### Outputs\n\n{outputs}\n"
    final_md += f"### Components\n\n{components}\n"
    final_md += f"### Keywords\n\n{keywords}\n"
    final_md += f"### Authors\n\n{', '.join(yaml_data['authors'])}\n\n"
    try:  # If no maintainers, then do not add the section.
        final_md += f"## Maintainers\n\n{', '.join(yaml_data['maintainers'])}\n\n"
    except KeyError:
        pass

    return final_md


def main():
    parser = _build_arg_parser()
    args = parser.parse_args()

    for subworkflow in [p for p in Path(args.subworkflows_dir).iterdir()
                                if p.is_dir()]:

        with open(subworkflow.joinpath("meta.yml").resolve(), 'r') as meta:
            md_data = convert_subworkflow_to_md(yaml.safe_load(meta))
            # Write the final markdown file.
            output_path = Path(args.output_dir).joinpath(
                f"{subworkflow.name}.md")
            output_path.write_text(md_data)


if __name__ == '__main__':
    main()
