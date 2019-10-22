-- Turns an element into a string, preserving math and footnote formatting for latex.
-- TO DO: glossing rules

function make_string(inlines)
    local buffer = ""
    for i, inline in ipairs(inlines) do
        buffer = buffer..to_tex(inline)
    end
    return buffer
end

-- Converts pandoc elements into relevant tex
function to_tex(inline)
    if inline.t == "Str" then
        if inline.text=="¶" then
            return "\\newline"
        else
            return pandoc.utils.stringify(inline)
        end
    elseif inline.t == "Math" then
        return "$"..inline.text.."$"
    elseif inline.t == "Note" then
        local ncon = pandoc.utils.blocks_to_inlines(inline.content)
        local buffer = ""
        for _, i in ipairs(inline.content) do
            buffer = buffer..to_tex(i)
        end
        return "\\footnote{"..buffer.."}"
    elseif inline.t == "Strong" then
        local buffer = ""
        for _, i in ipairs(inline.content) do
            buffer = buffer..to_tex(i)
        end
        return "\\textbf{"..buffer.."}"
    elseif inline.t == "Emph" then
        local buffer = ""
        for _, i in ipairs(inline.content) do
            buffer = buffer..to_tex(i)
        end
        return "\\textit{"..buffer.."}"
    elseif inline.t == "Strikeout" then
        local buffer = ""
        for _, i in ipairs(inline.content) do
            buffer = buffer..to_tex(i)
        end
        return "\\sout{"..buffer.."}"
    elseif inline.t == "SmallCaps" then
        local buffer = ""
        for _, i in ipairs(inline.content) do
            buffer = buffer..to_tex(i)
        end
        return "\\textsc{"..buffer.."}"
    elseif inline.t == "Quoted" then
        local buffer = ""
        for _, i in ipairs(inline.content) do
            buffer = buffer..to_tex(i)
        end
        if inline.quotetype == "SingleQuote" then
            return "'"..buffer.."'"
        else
            return '"'..buffer..'"'
        end
    elseif inline.t == "RawInline" then
        return inline.text
    elseif inline.t == "Space" then
        return " "
    elseif inline.t == "LineBreak" then
        return "\\\\"
    elseif inline.t == "SoftBreak" then
        return "\n"
    elseif inline.t == "Subscript" then
        local buffer = ""
        for _, i in ipairs(inline.content) do
            buffer = buffer..to_tex(i)
        end
        return "$_{\\text{"..buffer.."}}$"
    elseif inline.t == "Superscript" then
        local buffer = ""
        for _, i in ipairs(inline.content) do
            buffer = buffer..to_tex(i)
        end
        return "$^{\\text{"..buffer.."}}$"
    else
        print("Error in to_tex: "..inline.t)
        return "ERROR"
    end
end

function make_example(element)
    -- Gets label and content, if no label, then the else condition applies below.
    local label, cont = string.match(make_string(element), "<#(%w+)>(.*)$")
    if label then
        -- Assigns /ex tag and label
        local gloss = string.match(make_string(cont), "^\\gll ")
        return "\\ex\\label{" ..label.."}"..cont.."\n"
    else
        -- If element has no label, it groups with the upstairs element.
        return "\n"..make_string(element).."\n"
    end
end

-- This flattens embedded lists into xlists.
-- There should be a way to define this recursively, but I don't understand the data structures well enough.
-- E.g. every OrderedList could be turned into a list of elements butressed by raw "begin" and "end" latex code.
function create_xlist(element)
    return pandoc.walk_block(element, {
        OrderedList = function(ele)
            if ele.style ~= "Example" then
                local embex = ""
                for _, item in pairs(ele.content) do
                    embex = embex..filter_blocks(item)
                end
                embex = "\\begin{xlist}\n"..embex.."\\end{xlist}"
                -- no idea why Plain works here and RawBlock doesn't
                return pandoc.Plain(embex)
            else
                return ele
            end
        end
    })
end

function filter_blocks(item)
    inlines = pandoc.utils.blocks_to_inlines(item)
    return make_example(inlines)
end

-- replace <#numberedexample> with latex label
function OrderedList(element)
    if element.style == "Example" then
        local example = ""
        -- Turn 2nd level lists into xlists
        element = create_xlist(element)
        for _, item in pairs(element.content) do
            example = example..filter_blocks(item)
        end
        if example ~= "" then
            example = string.gsub(example, "(\\label{%w+}) \\newline", "%1")
            return pandoc.RawBlock("latex", "\\begin{exe}\n"..example.."\\end{exe}")
        end
    end
end

-- Replace <&labels> with latex ref
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

-- Puts my comments in the gnl tag.
-- NOTE: the logic here is what should be used to make the recursive rule for examples. 
function Span(element)
    if element.classes[1] == "gnl" then
        table.insert(element.content, 1, pandoc.RawInline('latex', '\\gnl{'))
        table.insert(element.content, pandoc.RawInline('latex', '}'))
    end
    return element
end
