# pandoc-templates

These are templates for pandoc. The pride and joy here is panling.lua, which is a lua filter that converts markdown to latex gb4e syntax in a fairly intuitive way.

## panling.lua

This will convert md-ish syntax into gb4e syntax for latex. It should now allow for multiple embedded examples. Inline math and other stylistic elements (md syntax or raw latex) (should) work as normal.

Glosses also work mostly as normal. Begin a gloss by appending "=gll" to the label tag (e.g., <#example>=gll), and delimit lines with single line breaks.

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
    (@) <#gloss>=gll C'est un exemple.
    \textsc{dem+cop} an example
    "This is an example."

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
