-- Creates xlist syntax for subexamples; similar logic as in the main function below.
-- TODO: This whole thing should be rewritten...

-- Get gb4e ready glosses from the AST span syntax created from includeex.lua
function Span(element)
    if element.classes[2] == "wilg" then
        local tags = {}
        -- Get tags and content
        for k, span in pairs(element.content) do
            if span.classes[1]=='ilg' and span.classes[2]=='trans' then
                tags[span.classes[2]] = span.content
            else
                tags[span.classes[2]] = span.content[1]
            end
        end
        local ilgLatex = {}
        if pandoc.utils.stringify(tags['context']) ~= '' then
            table.insert(ilgLatex, tags['context'])
            if pandoc.utils.stringify(tags['text']) ~= '' then
                table.insert(ilgLatex, pandoc.RawInline("latex","\\\\\n"))
            end
        end
        if pandoc.utils.stringify(tags['text']) ~= '' then
            table.insert(ilgLatex, tags['judgment'])
            table.insert(ilgLatex, tags['text'])
        end
        table.insert(ilgLatex, pandoc.RawInline("latex","\\gll "))
        table.insert(ilgLatex, tags['judgment'])
        table.insert(ilgLatex, tags['morph'])
        table.insert(ilgLatex, pandoc.RawInline("latex","\\\\\n"))
        table.insert(ilgLatex, tags['gloss'])
        table.insert(ilgLatex, pandoc.RawInline("latex","\\\\\n"))
        table.insert(ilgLatex, pandoc.RawInline("latex","\\trans "))
        for k, li in pairs(tags['trans']) do
            if li.t == "SoftBreak" then
                table.insert(ilgLatex, pandoc.RawInline("latex","\\\\\n"))
            else
                table.insert(ilgLatex, li)
            end
        end
        return ilgLatex
    end
end

-- Replace OrderedLists with gb4e syntax.
function OrderedList(element)
    if element.style == "Example" then
        element = create_xlists(element) --inserts xlist syntax.
        local exe = insert_ex(element, "exe") --inserts examples, returns list of inlines
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
