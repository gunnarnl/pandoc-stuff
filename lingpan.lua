-- Turns an element into a string, preserving math and footnote formatting for latex.
--      TO DO: need to make sure that small caps work. Also need to check on elements in elements. Probably will need a recursive rule.
function make_string(element)
    return pandoc.utils.stringify(pandoc.walk_block(element, {
        -- We want to preserve formatting for math, bf, notes, which will be obiliterated by stringify.
        Math = function(ele)
            return pandoc.Str("$"..ele.text.."$")
        end,
        Note = function(ele)
            return pandoc.Str("\\footnote{"..pandoc.utils.stringify(ele.content).."}")
        end,
        Strong = function(ele)
            return pandoc.Str("\\textbf{"..pandoc.utils.stringify(ele.content).."}")
        end,
        Emph = function(ele)
            return pandoc.Str("\\textit{"..pandoc.utils.stringify(ele.content).."}")
        end,
        SmallCaps = function(ele)
            return pandoc.Str("\\textsc{"..pandoc.utils.stringify(ele.content).."}")
        end
    }))
end

function make_example(element)
    -- Gets label and content, if no label, then the else condition applies below.
    local label, cont = string.match(make_string(element), "<#(%w+)>(.*)$")
    if label then
        -- Assigns /ex tag and label
        return "\\ex\\label{" ..label.."}"..cont.."\n"
    else
        -- If element has no label, it groups with the upstairs element.
        return "\n"..make_string(element).."\n"
    end
end

-- This flattens embedded lists into xlists.
function flattenembed(element)
    return pandoc.walk_block(element, {
        OrderedList = function(ele)
            if ele.style ~= "Example" then
                local embex = ""
                pandoc.walk_block(ele, {
                    Block = function(ele)
                        embex = embex..make_example(ele)
                    end
                })
                embex = "\\begin{xlist}\n"..embex.."\\end{xlist}"
                -- no idea why Plain works here and RawBlock doesn't
                return pandoc.Plain(embex)
            end
        end
    })
end

-- replace <#numberedexample> with latex label
function OrderedList(element)
    if element.style == "Example" then
        local example = ""
        --This will turn embedded lists into sublists for gb4e. This should be generalized.
        if element.t == "OrderedList" then
            element = flattenembed(element)
        end
        --This will flatten everything into a single string.
        pandoc.walk_block(element, {
            Block = function(ele)
                if ele.t ~= "OrderedList" then
                    example = example..make_example(ele)
                end
            end
        })
        -- Returns the flattened gb4e example.
        if example ~= "" then
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
