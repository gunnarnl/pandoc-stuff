---
    title: "Example"
    date: 3/16/20
---

# This example uses the handout files

This is a sentence.

This refers to <&label> below.

## This is also a header

(@) <#label> This is an **example and it contains *emphasis*.**

And there can be paragraphs in between.

(@) <#label2> This is a second example with math: $\exists x: \text{test} (x) \wedge \text{this} (x)$

    With a second paragraph.

(@) <#label3>
    1. <#sublabel1> This is a subexample.
    2. <#sublabel2> This is a second subexample with [small caps]{.smallcaps} and ~~strikeout~~.

This refers to the sublabel in <&sublabel1>. Glossing works as well, as in <&gloss>.

(@) <g#gloss> C'est un exemple.
\textsc{dem+cop} an example
"This is an example."

Or with an inserted example (with includeex.lua). By default, the context will appear if present. If the gloss contains both a text and morphemic breakdown, the text won't appear unless specified in the attributes. Also notice that "g" shouldn't be appended to the example reference.

(@) <#gloss2> [!id](glossing.json)

With attributes suppressText=false and suppressContext=true:

(@) <#gloss2> [!id](glossing.json){suppressText=false suppressContext=true}

Notice also that examples with only text, gloss, and translation work as expected.

(@) <#gloss3> [!id2](glossing.json)
