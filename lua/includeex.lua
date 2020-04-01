-- Replaces link syntax with interlinear glosses derived from a json format.
-- Actually outputs in native pandoc for now, where each part of the gloss is a span with the appropriate tag.
-- Link syntax: [!identifier](file.json){attributes}

-- TO DO: error messages, parse linebreaks as linebreaks
-- Eventually: html.

local lunajson = require 'lunajson'
local List = require 'pandoc.List'

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
        local sents = List:new(jsonCont.sentences)
        local sent = sents:find_if(has_id(refID))
        -- Output specific outputs:
        if FORMAT:match 'latex' then
            return ILGlatex(sent, suppressText, suppressContext)
        elseif FORMAT:match 'html' then
            return ILGhtml(sent, suppressText, suppressContext)
        end
    end
end

function ILGlatex(sent, suppressText, suppressContext)
    local result = List:new()
    --local sent = jsonsents:find_if(has_id(refID))
    -- for i, item in pairs(jsonsents) do
    --     if item.ref == refID then
    --         sent = item
    --     end
    -- end
    local judgment = ""
    if sent.judgment ~= nil then
        judgment = sent.judgment
    end
    --Context level
    if suppressContext==false and sent.context ~= nil then
        result:insert(pandoc.Str(sent.context))
    end
    --Text level
    if suppressText==false then
        result:insert(pandoc.Str(judgment))
        result:insert(pandoc.Str(sent.text))
        judgment = "" -- reset judgment so it isn't doubled below
    end
    --Morphemic level
    if sent.morph ~= nil then
        result:insert(pandoc.RawInline("latex","\\gll "))
        result:insert(pandoc.Str(judgment))
        result:insert(pandoc.Str(table.concat(sent.morph, " ")))
    else
        result:insert(pandoc.RawInline("latex","\\gll "))
        result:insert(pandoc.Str(judgment))
        result:insert(pandoc.Str(sent.text))
    end
    result:insert(pandoc.RawInline("latex","\\\\\n"))
    --Gloss level
    result:insert(pandoc.Str(table.concat(sent.gloss, " ")))
    result:insert(pandoc.RawInline("latex","\\\\\n"))
    --Translation level
    result:insert(pandoc.RawInline("latex","\\trans "))
    for i, string in pairs(split(sent.trans, "\n")) do
        result:insert(pandoc.Str(string))
        result:insert(pandoc.RawInline("latex","\\\\\n"))
    end
    result:remove()
    return result
end

function ILGhtml(sent, suppressText, suppressContext)
    local result = List:new()
    local morphs = List:new()
    local glosses = List:new(sent.gloss)
    local judgment = ""
    if sent.judgment ~= nil then
        judgment = sent.judgment
    end
    if sent.morph ~= nil then
        morphs:extend(sent.morph)
    else
        morphs:extend(split(sent.text))
    end
    len = num_gloss_pairs(morphs, glosses)
    result:insert(pandoc.RawInline('html', '<table class="ilg">'))
    -- Context level
    if suppressContext == false and sent.context ~= nil then
        result:extend(html_row_ins(sent.context, len, 'context'))
    end
    -- Text level
    if suppressText == false then
        result:extend(html_row_ins(judgment..sent.text, len, 'text'))
        judgment = ""
    end
    -- Morphemic level
    result:extend(html_mgpairs_row_ins(judgment, morphs, "morph"))
    -- Gloss level
    result:extend(html_mgpairs_row_ins(judgment, glosses, "gloss"))
    -- Translation level
    result:extend(html_row_ins(sent.trans, len, 'trans'))
    result:insert(pandoc.RawInline('html', '</table>'))
    return result
end

function has_id (id)
  return function(x) return x.ref == id end
end

function num_gloss_pairs(morph, gloss)
    if #morph ~= #gloss then
        print("!: Number of morphs differs from number of glosses.")
        return 100
    else
        return #gloss
    end
end

function html_row_ins(contents, colnum, type)
    result = List:new()
    result:insert(pandoc.RawInline('html', '<tr class='..type..'><td colspan='..colnum..'>'))
    for i, string in pairs(split(contents, "\n")) do
        result:insert(pandoc.Str(string))
        result:insert(pandoc.RawInline('html', '<br>'))
    end
    result:remove()
    result:insert(pandoc.RawInline('html', '</td></tr>'))
    return result
end

function html_mgpairs_row_ins(judgment, items, type)
    result = List:new()
    result:insert(pandoc.RawInline('html', '<tr class='..type..'><td class="judgment">'..judgment..'</td>'))
    for i, item in pairs(items) do
        result:insert(pandoc.RawInline('html', '<td class="'..type..'">'))
        result:insert(pandoc.Str(item))
        result:insert(pandoc.RawInline('html', '</td>'))
    end
    result:insert(pandoc.RawInline('html', '</tr>'))
    return result
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
