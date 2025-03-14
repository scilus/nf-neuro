#!/usr/bin/env python
# -*- coding: utf-8 -*-

import glob
import json
import os
import platform
import shutil

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

# Assert that the template is available.
tpls = tf.api.templates()
assert '${template}' in tpls, "Template ${template} not found in %s." % tpls

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

# Moving the files to the output directory.
# This is to make files from the template directly accessible
# within channels.
print("You asked for ${template} at resolution: ${res} \
        for cohort: ${cohort}. Trying to find them...")
for suffix in ["T1w", "T2w", "desc-brain_mask", "label-CSF_probseg",
                "label-GM_probseg", "label-WM_probseg"]:
    if '${cohort}' != "":
        path = glob.glob(
            "tpl-${template}/${cohort}/*${template}*${res}_%s.nii.gz" % suffix
        )
    else:
        path = glob.glob(
            "tpl-${template}/*${template}*${res}_%s.nii.gz" % suffix
        )
    if len(path) == 0:
        # In some cases for some templates, it would not catch any files
        # even though they are there. In those cases, only the folder will
        # will be in the output channels. Using print() because it is not
        # an error.
        print("Unable to find %s for ${template} at resolution: ${res} \
                for cohort: ${cohort}. Please validate it exists in the \
                templateflow directory. Otherwise, the template folder \
                will still be accessible in the process output \
                channels." % suffix)
    else:
        filename = os.path.basename(path[0])
        shutil.copy(
            path[0],
            os.path.join(
                os.getcwd(),
                filename
            )
        )

# Export versions.
versions = {
    "${task.process}": {
        "templateflow": tf.__version__,
        "python": platform.python_version(),
    }
}

with open("versions.yml", "w") as f:
    f.write(format_yaml_like(versions))
