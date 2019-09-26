# pandoc-templates

These are templates for pandoc. The pride and joy here is panling.lua, which is a lua filter that converts markdown to latex gb4e syntax in a fairly intuitive way.

## panling.lua

This will convert md-ish syntax into gb4e syntax for latex. It currently allows for one layer of embedding. I don't really know lua at all nor pandoc's lua support, so I'm sure there's a way to generalize to multiple embeddings. Inline math (should) work as normal.

The syntax for this:

    (@) <#label> This is an example

    And there can be paragraphs in between.

    (@) <#label2> This is a second example with math: $\exists x: \text{test}(x) \wedge \textsc{this}(x)$

        With a second paragraph.

    (@) <#label3>
        1. <#sublabel1> This is a subexample.
        2. <#sublabel2> This is a second subexample.

## Templates
.yaml files are metadata, header-\*.tex files are the header info for .tex/.pdf conversion.

Handouts:
+ handout.yaml
+ header-handout.tex

Articles:
+ article.yaml
+ header-article.tex

## Typical usage

    pandoc metadata.yaml src.md -o src.pdf -H header.tex --lua-filter=panling.lua
