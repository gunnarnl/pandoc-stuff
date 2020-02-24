-- Replaces link syntax with interlinear glosses derived from a json format.
-- Actually outputs in native pandoc for now, where each part of the gloss is a span with the appropriate tag.
-- Link syntax: [!identifier](file.json){attributes}

-- TO DO: error messages, parse linebreaks as linebreaks
-- Eventually: html.

local lunajson = require 'lunajson'

function Link(element)
    if string.match(pandoc.utils.stringify(element.content), "^!") then
        local suppressText = true
        local suppressContext = false
        local refID = string.match(pandoc.utils.stringify(element.content), "^!(.*)")
        if element.attributes.suppressText=="false" then
            suppressText = false
        end
        if element.attributes.suppressContext=="true" then
            suppressContext = true
        end
        local fileCont = io.open(element.target, "r"):read("a")
        local jsonCont = lunajson.decode(fileCont)
        local sents = jsonCont.sentences
        local ilg = {}
        for k, sent in pairs(sents) do
            if sent.ref == refID then
                local context = pandoc.Span({pandoc.Str("")}, pandoc.Attr(sent.ref.."context", {'ilg', 'context'}))
                local text = pandoc.Span({pandoc.Str("")}, pandoc.Attr(sent.ref.."text", {'ilg', 'text'}))
                if sent.context ~= nil and suppressContext==false then
                    context = pandoc.Span({pandoc.Str(sent.context), pandoc.SoftBreak()}, pandoc.Attr(sent.ref.."context", {'ilg', 'context'}))
                    --table.insert(ilg, context)
                end
                if suppressText==false then
                    text = pandoc.Span({pandoc.Str(sent.text), pandoc.SoftBreak()}, pandoc.Attr(sent.ref.."text", {'ilg', 'text'}))
                    morph = pandoc.Span({pandoc.Str(table.concat(sent.morph, " ")), pandoc.SoftBreak()}, pandoc.Attr(sent.ref.."morph", {'ilg', 'morph'}))
                else
                    if sent.morph ~= nil then
                        morph = pandoc.Span({pandoc.Str(table.concat(sent.morph, " ")), pandoc.SoftBreak()}, pandoc.Attr(sent.ref.."morph", {'ilg', 'morph'}))
                    else

                        morph = pandoc.Span({pandoc.Str(sent.text), pandoc.SoftBreak()}, pandoc.Attr(sent.ref.."morph", {'ilg', 'morph'}))
                    end
                end
                gloss = pandoc.Span({pandoc.Str(table.concat(sent.gloss, " ")), pandoc.SoftBreak()}, pandoc.Attr(sent.ref.."gloss", {'ilg', 'gloss'}))
                table.insert(ilg, context)
                table.insert(ilg, text)
                table.insert(ilg, morph)
                table.insert(ilg, gloss)
                local transStr = split(sent.trans, "\n")
                local trans = {}
                for k, string in pairs(transStr) do
                    table.insert(trans, pandoc.Str(string))
                    table.insert(trans, pandoc.SoftBreak())
                end
                transSpan = pandoc.Span(trans, pandoc.Attr(sent.ref.."trans", {'ilg', 'trans'}))
                table.insert(ilg, transSpan)
                ilg = pandoc.Span(ilg, pandoc.Attr(sent.ref.."ilg", {'ilg', 'wilg'}))
            end
        end
        return ilg
    end
end

function split(strin, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(strin, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end
