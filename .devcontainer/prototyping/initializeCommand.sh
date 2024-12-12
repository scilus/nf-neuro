#!/usr/bin/env bash

# The prototyping environment must not be started in the nf-neuro repository.

if [[ $PWD =~ .*/nf-neuro$ ]]
then

echo "You cannot open a prototyping environment in the nf-neuro repository."
echo "Please, locate yourself elsewhere, outside the nf-neuro tree if possible."

exit 1

fi
