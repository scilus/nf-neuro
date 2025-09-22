import argparse
from pathlib import Path
import yaml
import datetime

from jinja2 import Environment, FileSystemLoader, select_autoescape


DOC_URL_BASE="https://scilus.github.io/nf-neuro"


def channel_description_format(description):
    _descr = description.split("\n")
    try:
        _structure = next(filter(lambda x: "Structure:" in x, _descr))
    except StopIteration:
        return " ".join(_descr)

    _descr.remove(_structure)
    _structure = _structure.replace('[', '`[').replace(']', ']`')
    return f"{' '.join(_descr)}<br /><br />{_structure}"


def component_format(component):
    ctype = "module" if "/" in component else "subworkflow"
    return f"[{component}]({DOC_URL_BASE}/api/{ctype}s/{component})"


def link(text, url=None):
    if not url:
        return text
    return f"[{text}]({url})"


def _create_parser():
    p = argparse.ArgumentParser(
            description='Generate subworkflow markdown from template',
            formatter_class=argparse.RawTextHelpFormatter)

    p.add_argument('subworkflow_path', help='Name of the subworkflow')
    p.add_argument('current_commit_sha', help='Current commit sha')
    p.add_argument('output', help='Name of the output markdown file')

    return p


def main():
    parser = _create_parser()
    args = parser.parse_args()

    env = Environment(
        loader=FileSystemLoader('docs/astro/templates'),
        autoescape=select_autoescape()
    )
    env.filters.update({
        'component_format': component_format,
        'link_tool': link,
        'channel_descr': channel_description_format
    })

    with open(f"{args.subworkflow_path}/meta.yml", "r") as f:
        data = yaml.safe_load(f)

    data["currentcommit"] = args.current_commit_sha
    data["currentdate"] = datetime.datetime.now().strftime("%Y-%m-%d")

    template = env.get_template('subworkflow.md.jinja2')
    output_path = Path(args.output)
    output_path.write_text(template.render(**data))


if __name__ == "__main__":
    main()
