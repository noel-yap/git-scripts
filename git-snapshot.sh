#!/bin/bash

git stash push "$@"
git stash apply
