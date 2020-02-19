-- Replaces link syntax with interlinear glosses derived from a json format.
-- For now: outputs in raw latex.
-- Link syntax: [!identifier](file.json){attributes}

-- TO DO: error messages. Eventually: html.

local lunajson = require 'lunajson'

local suppressText = true
local suppressContext = false

function Link(element)
    if string.match(pandoc.utils.stringify(element.content), "^!") then
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
        local context = ""
        local text = ""
        local morph = ""
        local gloss = ""
        local ft = ""
        local ilg = {}
        for k, sent in pairs(sents) do
            if sent.ref == refID then
                if sent.context ~= nil and suppressContext==false then
                    context = sent.context
                    table.insert(ilg, pandoc.Str(context))
                end
                if suppressText==true and sent.morph ~= nil then
                    morph = table.concat(sent.morph, " ")
                    table.insert(ilg, pandoc.RawInline("latex", "\\gll "))
                    table.insert(ilg, pandoc.Str(morph))
                elseif suppressText==false and sent.morph ~= nil then
                    morph = table.concat(sent.morph, " ")
                    table.insert(ilg, pandoc.Str(sent.text))
                    table.insert(ilg, pandoc.RawInline("latex", "\\gll "))
                    table.insert(ilg, pandoc.Str(morph))
                else
                    table.insert(ilg, pandoc.RawInline("latex", "\\gll "))
                    table.insert(ilg, pandoc.Str(sent.text))
                end
                table.insert(ilg, pandoc.RawInline("latex", "\\\\\n"))
                gloss = table.concat(sent.gloss, " ")
                table.insert(ilg, pandoc.Str(gloss))
                table.insert(ilg, pandoc.RawInline("latex", "\\\\\n\\trans "))
                table.insert(ilg, pandoc.Str(sent.trans))
            end
        end
        return ilg
    end
end
