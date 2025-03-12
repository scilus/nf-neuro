#!/usr/bin/env python
# -*- coding: utf-8 -*-

import json
import os
import platform

# Its ugly, but for some reasons this needs to be set
# prior to importing templateflow, otherwise it will
# return an error.
os.environ["TEMPLATEFLOW_HOME"] = os.path.join(os.getcwd())

import templateflow as tf


def format_yaml_like(data: dict, indent: int = 0) -> str:
    """Formats a dictionary to a YAML-like string.
    Pulled from the scvitools/solo nf-core modules.
    https://github.com/nf-core/modules/nf-core/scvitools/solo/templates/solo.py

    Args:
        data (dict): The dictionary to format.
        indent (int): The current indentation level.

    Returns:
        str: A string formatted as YAML.
    """
    yaml_str = ""
    for key, value in data.items():
        spaces = "    " * indent
        if isinstance(value, dict):
            yaml_str += f"{spaces}{key}:\\n{format_yaml_like(value, indent+1)}"
        else:
            yaml_str += f"{spaces}{key}: {value}\\n"
    return yaml_str


# Set up templateflow home folder in work directory.
tf.conf.setup_home(force=True)

# Fetch the specified template.
tf.api.get('${template}')
metadata = tf.api.get_metadata('${template}')

# Convert it into a .txt file.
with open("${template}_metadata.json", "w") as f:
    f.write(json.dumps(metadata))

citation = tf.api.get_citations("${template}")

# Convert it into a .txt file.
with open("${template}_citations.bib", "w+") as f:
    for items in citation:
        f.write('%s\\n' % items)

# Export versions.
versions = {
    "${task.process}": {
        "templateflow": tf.__version__,
        "python": platform.python_version(),
    }
}

with open("versions.yml", "w") as f:
    f.write(format_yaml_like(versions))
