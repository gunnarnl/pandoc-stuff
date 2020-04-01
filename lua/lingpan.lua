-- Creates xlist syntax for subexamples; similar logic as in the main function below.
-- TODO: This whole thing should be rewritten...

-- Get gb4e ready glosses from the AST span syntax created from includeex.lua

local List = require 'pandoc.List'

-- NEW WAY TO DO THIS: CREATE A LIST AND THEN CONCATENATE
function Span(element)
    if element.classes[2] == "wilg" then
        local tags = {}
        -- Get tags and content
        for k, span in pairs(element.content) do
            tags[span.classes[2]] = span.content
        end
        --- Do the rest based on the output format ---
        if FORMAT:match 'latex' then
            return ILGlatex(element, tags)
        elseif FORMAT:match 'html' then
            return ILGhtml(element, tags)
        else
            print("lingpan.lua: Output format not supported")
        end
    end
end

function ILGlatex(element, tags)
    -- NOTE: may need to concatenate morphs and glosses.
    local result = List:new()
    if pandoc.utils.stringify(tags['context']) ~= '' then
        result:extend(tags['context'])
        if pandoc.utils.stringify(tags['text']) ~= '' then
            result:insert(pandoc.RawInline("latex","\\\\\n"))
        end
    end
    if pandoc.utils.stringify(tags['text']) ~= '' then
        result:extend(tags['judgment'])
        result:extend(tags['text'])
    end
    result:insert(pandoc.RawInline("latex","\\gll "))
    result:extend(tags['judgment'])
    result:extend(tags['morph'])
    result:insert(pandoc.RawInline("latex","\\\\\n"))
    result:extend(tags['gloss'])
    result:insert(pandoc.RawInline("latex","\\\\\n"))
    result:insert(pandoc.RawInline("latex","\\trans "))
    result:extend(tags['trans']:map(SwapBreaks))
    -- Return a list of inlines.
    return result
end

function SwapBreaks(li)
    print("Hello!")
    if li.t == "SoftBreak" then
        return pandoc.RawInline('latex', '\\\\\n')
    else
        return li
    end
end

function ILGhtml(element, tags)
    -- FOR NOW: ILGs are going to have to be split apart here even though that's dumb. Concatenating should happen in the above code so deconcatenating doesn't have to happen here.

    -- Get number of morphs
    if #tags['morph'] ~= #tags['gloss'] then
        print("ERROR: Number of morphs differs from number of glosses.")
    else
        lenM = #tags['morph']
    end
    local ilglist = {}
    table.insert(ilglist, pandoc.RawInline('html', '<table>'))
    if pandoc.utils.stringify(tags['context']) ~= '' then
        table.insert(ilglist, tags['context'])
        if pandoc.utils.stringify(tags['text']) ~= '' then
            table.insert(ilgtexlist, pandoc.RawInline("latex","\\\\\n"))
        end
    end
    if pandoc.utils.stringify(tags['text']) ~= '' then
        table.insert(ilgtexlist, tags['judgment'])
        table.insert(ilgtexlist, tags['text'])
    end
    table.insert(ilglist, pandoc.RawInline('html', '<tr>'))
end

-- Replace OrderedLists with gb4e syntax.
function OrderedList(element)
    if element.style == "Example" then
        element = create_xlists(element) --inserts xlist syntax.
        local exe = insert_ex(element) --inserts examples, returns list of inlines
        table.insert(exe, 1, pandoc.RawBlock("latex", "\\begin{exe}"))
        table.insert(exe, pandoc.RawBlock("latex", "\\end{exe}"))
        return pandoc.Div(exe)
    end
end

-- Get labels and add glossing support when tag has g.
function get_label(element)
    local gloss = false
    g, label = string.match(pandoc.utils.stringify(element), "^<(g?)#([%s%w%-:]+)>")
    element[1].content[1] = pandoc.Str("") --remove label
    -- element[1].content[1] = pandoc.Null() --remove label
    if g == "g" then
        gloss = true
    end
    return label, gloss, element
end

--Inserts xlist syntax on embedded lists
function create_xlists(element)
    return pandoc.walk_block(element, {
        OrderedList = function(ele)
            if ele.style ~= "Example" then
                local result = insert_ex(ele)
                table.insert(result, 1, pandoc.RawBlock("latex", "\\begin{xlist}"))
                table.insert(result, pandoc.RawBlock("latex", "\\end{xlist}"))
                return pandoc.Div(result)
            end
        end
    })
end

-- Takes list items and inserts \ex\label{}.
function insert_ex(element)
    local result = {}
    for _, li in pairs(element.content) do
        local label, gloss, li = get_label(li)
        if gloss == true then --Inserts gll stuff
            table.insert(li[1].content, 1, pandoc.RawInline("latex", "\\gll"))
            li[1] = pandoc.walk_block(li[1], {
                SoftBreak = function(ele)
                    return pandoc.RawInline("latex","\\\\\n")
                end
            })
        end
        table.insert(li[1].content, 1, pandoc.RawInline("latex", "\\ex\\label{"..label.."} "))
        for _, block in pairs(li) do
            table.insert(result, block)
        end
    end
    return result
end

-- Replace <&labels> with latex /ref{}
function Str(element)
    if string.match(element.text, "<%&([%s%w%-:]+)>") then
        local label, punc = string.match(element.text, "<%&([%s%w%-:]+)>(%p*)")
        if punc==nil then
            punc = ""
        end
        return pandoc.RawInline("latex", "(\\ref{"..label.."})"..punc)
    else
        return element
    end
end
