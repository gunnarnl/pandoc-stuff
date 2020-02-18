-- Replaces link syntax with interlinear glosses derived from a json format.
-- For now: outputs in raw latex.
-- Link syntax: [!identifier](file.json){attributes}

-- TO DO: error messages. Eventually: html.

local lunajson = require 'lunajson'

local suppressText = true
local suppressContext = false

function Link(element)
    if string.match(pandoc.utils.stringify(element.content), "^!") then
        if element.attributes.suppressText=="false" then
            suppressText = false
        end
        if element.attributes.suppressContext=="true" then
            suppressContext = true
        end
        local fileCont = io.open(element.target, "r"):read("a")
        local jsonCont = lunajson.decode(fileCont)
        local refID = string.match(pandoc.utils.stringify(element.content), "^!(.*)")
        local sents = jsonCont.sentences
        local context = ""
        local text = ""
        local morph = ""
        local gloss = ""
        local ft = ""
        for k, sent in pairs(sents) do
            if sent.ref == refID then
                if sent.context ~= nil and suppressContext==false then
                    context = sent.context.."\\\n"
                end
                if suppressText==true and sent.morph ~= nil then
                    morph = table.concat(sent.morph, " ")
                elseif suppressText==false and sent.morph ~= nil then
                    text = sent.text.."\\\n"
                    morph = table.concat(sent.morph, " ")
                else
                    morph = sent.text
                end
                gloss = table.concat(sent.gloss, " ")
                ft = sent.trans
            end
        end
        return pandoc.RawInline("latex", context..text.."\\gll "..morph.."\\\\\n"..gloss.."\\\\\n\\trans '"..ft.."'")
    end
end
