-- Creates xlist syntax for subexamples; similar logic as in the main function below.
-- TODO: This whole thing should be rewritten...

function create_xlists(element)
    return pandoc.walk_block(element, {
        OrderedList = function(ele)
            if ele.style ~= "Example" then
                local result = insert_ex(ele, "xlist")
                table.insert(result, 1, pandoc.RawBlock("latex", "\\begin{xlist}"))
                table.insert(result, pandoc.RawBlock("latex", "\\end{xlist}"))
                return pandoc.Div(result)
            end
        end
    })
end

-- Get gb4e ready glosses.
-- TODO: make newlines work in translations!
function Span(element)
    if element.classes[2] == "wilg" then
        local tags = {}
        for k, span in pairs(element.content) do
            if span.classes[1] == 'ilg' and span.classes[2]~='trans' then
                tags[span.classes[2]] = span.content[1]
            elseif span.classes[1]=='ilg' and span.classes[2]=='trans' then
                tags[span.classes[2]] = pandoc.Str(pandoc.utils.stringify(span.content))
            else
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
            table.insert(ilgLatex, tags['text'])
        end
        table.insert(ilgLatex, pandoc.RawInline("latex","\\gll "))
        table.insert(ilgLatex, tags['morph'])
        table.insert(ilgLatex, pandoc.RawInline("latex","\\\\\n"))
        table.insert(ilgLatex, tags['gloss'])
        table.insert(ilgLatex, pandoc.RawInline("latex","\\\\\n"))
        table.insert(ilgLatex, pandoc.RawInline("latex","\\trans "))
        table.insert(ilgLatex, tags['trans'])
        return ilgLatex
    end
end

-- Get labels and add glossing support when tag has =gll.
function get_label(element)
    label, gl = string.match(pandoc.utils.stringify(element), "^<#([%s%w%-:]+)>([=gll]*)")
    if gl ~= "" then
        local buffer = {}
        for _, block in pairs(element) do
            table.insert(block.content, 1, pandoc.RawInline("latex", "\\gll"))
            block = pandoc.walk_block(block, {
                SoftBreak = function(ele)
                    return pandoc.RawInline("latex","\\\\\n")
                end
            })
            table.insert(buffer, block)
        end
        return label, buffer
    else
        return label, element
    end
end

-- Replace OrderedLists with gb4e syntax.
function OrderedList(element)
    if element.style == "Example" then
        element = create_xlists(element)
        local result = insert_ex(element, "exe")
        table.insert(result, 1, pandoc.RawBlock("latex", "\\begin{exe}"))
        table.insert(result, pandoc.RawBlock("latex", "\\end{exe}"))
        return pandoc.Div(result)
    end
end

-- Takes list items and inserts \ex\label{}.
function insert_ex(element, labeltype)
    local result = {}
    for _, li in pairs(element.content) do
        local label, li = get_label(li)
        --table.insert(li[1].content, 1, pandoc.RawInline("latex", "\\ex\\label{"..label.."}"))
        local judgment = ""
        table.insert(li[1].content, 1, pandoc.RawInline("latex", "\\ex["..judgment.."]{"))
        table.insert(li[1].content, pandoc.RawInline("latex", "}\\label{"..label.."}"))
        for _, block in pairs(li) do
            -- Removes labels
            block = pandoc.walk_block(block, {
                Str = function(ele)
                    if string.match(ele.text, "^<#([%s%w%-:]+)>([=gll]*)") then
                        return pandoc.SoftBreak()
                    else
                        return ele
                    end
                end
            })
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
