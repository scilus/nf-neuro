## Describe your changes

## List test packages used by your subworkflow

## Checklist before requesting a review

- Create the tool:
  - [ ] Edit `./subworkflows/nf-neuro/<category>/<tool>/main.nf`
  - [ ] Edit `./subworkflows/nf-neuro/<category>/<tool>/meta.yml`
- Generate the tests:
  - [ ] Edit `./subworkflows/nf-neuro/<category>/<tool>/tests/main.nf.test`
  - [ ] Run the tests to generate the `main.nf.test.snap` snapshots
- Ensure the syntax is correct :
  - [ ] Run `prettier` and `editorconfig-checker` to fix common syntax issues
  - [ ] Run `nf-core subworkflows lint` and fix all errors
  - [ ] Ensure your variables have good, clear names
