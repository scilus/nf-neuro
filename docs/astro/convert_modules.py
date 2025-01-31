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
            description='Convert modules YAML to a Markdown files',
            formatter_class=argparse.RawTextHelpFormatter)

    p.add_argument('modules_dir', help='Path to the modules directory')
    p.add_argument('output_dir', help='Path to output the Markdown files')

    return p


def convert_module_to_md(yaml_data):
    # Order:
    # Inputs
    # Params
    # outputs
    # Tools
    # Keywords

    # Take the module name and replace the _ by /.
    module_name = yaml_data['name'].replace("_", "/")
    # Take only the second part of the module name.
    short_name = module_name.split("/")[1]

    # Create a table for the Keywords section.
    keywords = "|  |\n"
    keywords += "|----------|\n"
    for keyword in yaml_data['keywords']:
        keywords += f"| {keyword} |\n"

    # Table for the tools section.
    tools = "|  | Description | Homepage | DOI |\n"
    tools += "|------|-------------|----------|-----|\n"
    for tool in yaml_data['tools']:
        name = next(iter(tool))
        description = tool[name]['description'].replace("\n", " ")
        homepage = tool[name].get('homepage', "").replace("\n", " ")
        doi = tool[name].get('doi', "").replace("\n", " ")
        tools += f"| {name} | {description} | {homepage} | {doi} |\n"

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
    final_md += f"title: {short_name}\n"
    final_md += "---\n\n"

    final_md += f"## Module: {module_name}\n\n{yaml_data['description']}\n\n"
    final_md += f"### Inputs\n\n{inputs}\n"
    if params != "":
        final_md += f"### Parameters\n\n{params}\n"
    final_md += f"### Outputs\n\n{outputs}\n"
    final_md += f"### Tools\n\n{tools}\n"
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

    for category in [p for p in Path(args.modules_dir).iterdir() if p.is_dir()]:
        for module in [p for p in category.iterdir() if p.is_dir()]:
            with open(module.joinpath('meta.yml').resolve(), 'r') as meta:
                md_data = convert_module_to_md(yaml.safe_load(meta))
                # Write the final markdown file.
                output_path = Path(args.output_dir).joinpath(
                    f"{category.name}_{module.name}.md")
                output_path.write_text(md_data)


if __name__ == '__main__':
    main()
