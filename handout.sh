#!/bin/bash

pandoc ~/Projects/pandoc-templates/handout.yaml $1 -o $2 -H ~/Projects/pandoc-templates/header-handout.tex --lua-filter ~/Projects/pandoc-templates/lingpan.lua
