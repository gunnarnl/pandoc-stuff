# pandoc-templates

My personal templates and lua filters for pandoc. The pride and joy here is lingpan.lua, which is a lua filter that converts intuitive markdown-like syntax to latex gb4e syntax.

## lingpan.lua

This will convert md-ish syntax into gb4e syntax for latex. It should now allow for multiple embedded examples. Inline math and other stylistic elements (md syntax or raw latex) (should) work as normal.

Glosses also work mostly as normal. Begin a gloss by inserting "g" before the "#" in the label tag (e.g., <g#example>), and delimit lines with single line breaks.

The syntax for this:

    (@) <#label> This is an example

    And there can be paragraphs in between.

    (@) <#label2> This is a second example with math: $\exists x: \text{test}(x) \wedge \textsc{this}(x)$

        With a second paragraph.

    (@) <#label3>
        1. <#sublabel1> This is a subexample.
        2. <#sublabel2> This is a second subexample.

    References to examples can be made with <&label>.

    Glossing is mostly familiar (notice that soft breaks can be used here to delineate data, gloss, and translation).
    (@) <g#gloss> C'est un exemple.
    \textsc{dem+cop} an example
    "This is an example."

## includeex.lua

Inserts interlinear glosses from an external file formatted in JSON, where *ref* is a unique identifier for the gloss. Requires lunajson module for lua5.3.

Syntax:

    [!ref](file.json){attributes}

This is included in the examples. Also look there for a sample JSON file.

## Templates
.yaml files are metadata, header-\*.tex files are the header info for .tex/.pdf conversion.

Handouts:
+ handout.yaml
+ header-handout.tex

Articles:
+ article.yaml
+ header-article.tex

## pancomp

BASH script for using quickly creating pdfs using filters and templates.

    pancomp [options] filetoconvert.md

Options:

-a: Use article header and yaml files.

-o [FILENAME]: use specified filename (don't include extension)

-t [.EXT]: use specified extension (include .!)  

## Typical usage otherwise

    pandoc metadata.yaml src.md -o src.pdf -H header.tex --lua-filter=panling.lua
