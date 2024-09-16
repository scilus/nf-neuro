## Describe your changes

## List test packages used by your module

## Checklist before requesting a review

- Create the tool:
  - [ ] Edit `./modules/nf-neuro/<category>/<tool>/main.nf`
  - [ ] Edit `./modules/nf-neuro/<category>/<tool>/meta.yml`
  - [ ] Edit `./modules/nf-neuro/<category>/<tool>/environment.yml`
- Generate the tests:
  - [ ] Edit `./modules/nf-neuro/<category>/<tool>/tests/main.nf.test`
  - [ ] Run the tests to generate the `main.nf.test.snap` snapshots
- Ensure the syntax is correct :
  - [ ] Run `prettier` and `editorconfig-checker` to fix common syntax issues
  - [ ] Run `nf-core modules lint` and fix all errors
  - [ ] Ensure your variables have good, clear names
