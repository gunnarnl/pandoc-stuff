-- Creates xlist syntax for subexamples; similar logic as in the main function below.
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

-- Get labels and add glossing support when tag has =gll.
function get_label(element)
    label, gl = string.match(pandoc.utils.stringify(element), "^<#(%w+)>([=gll]*)")
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
        return buffer, label
    else
        return element, label
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
        li, label = get_label(li)
        table.insert(li[1].content, 1, pandoc.RawInline("latex", "\\ex\\label{"..label.."}"))
        for _, block in pairs(li) do
            -- Removes labels
            block = pandoc.walk_block(block, {
                Str = function(ele)
                    if string.match(ele.text, "^<#(%w+)>([=gll]*)") then
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
    if string.match(element.text, "<%&(%w+)>") then
        local label, punc = string.match(element.text, "<%&(%w+)>(%p*)")
        if punc==nil then
            punc = ""
        end
        return pandoc.RawInline("latex", "(\\ref{"..label.."})"..punc)
    else
        return element
    end
end
