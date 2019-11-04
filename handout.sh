#!/bin/bash

pandoc ~/Projects/pandoc-templates/handout.yaml $1 -o $2 -H ~/Projects/pandoc-templates/header-handout.tex --filter pandoc-citeproc --lua-filter ~/Projects/pandoc-templates/lingpan.lua --lua-filter ~/Projects/pandoc-templates/gnl.lua
