-- TODO: Make html glosses work

local List = require 'pandoc.List'

--- Main OrderedList function
function OrderedList(element)
    if element.style == "Example" then
        if FORMAT:match 'latex' then
            return latex_rules(element) -- returns Div
        elseif FORMAT:match 'html' then
            return html_rules(element) -- returns OrderedList
        end
    end
end

---------------------------
--- Universal functions ---
---------------------------
-- Get labels and add glossing support when tag has g.
function get_label(li)
    local gloss = false
    g, label = string.match(pandoc.utils.stringify(li), "^<(g?)#([%s%w%-:]+)>")
    li[1].content[1] = pandoc.Str("") --remove label
    if g == "g" then
        gloss = true
    end
    return label, gloss, li
end

----------------------
--- Html functions ---
----------------------
-- Main function
function html_rules(element)
    startnum = element.start
    element = html_sublists(element, num)
    element = html_labels(element, startnum)
    return element
end

-- Replace labels in sublists
function html_sublists(element, num)
    return pandoc.walk_block(element, {
        OrderedList = function(ele)
            if ele.style ~= "Example" then
                return html_labels(ele, num)
            end
        end
    })
end

-- Remove md labels and insert anchors.
function html_labels(element, num)
    result = List:new()
    for j, li in pairs(element.content) do
        local label, gloss, li = get_label(li)
        li = insert_html_anchor(li, label, num)
        result:insert(li)
    end
    element.content = result
    return element
end

-- Inserts anchor in list item
function insert_html_anchor(li, label, num)
    table.insert(li[1].content, 1, pandoc.RawInline('html', '<a id='..label..'-label></a>'))
    return li
end

-----------------------
--- Latex functions ---
-----------------------
-- Main function
function latex_rules(element)
    element = create_xlists(element) -- inserts xlist tags
    return ins_gb4e_span(element, 'exe')
end

--Inserts xlist syntax on embedded lists
function create_xlists(element)
    return pandoc.walk_block(element, {
        OrderedList = function(ele)
            if ele.style ~= "Example" then
                return ins_gb4e_span(ele, 'xlist')
            end
        end
    })
end

-- Inserts the relevant gb4e scope markers.
function ins_gb4e_span(element, type)
    local result = List:new(insert_ex(element))
    result:insert(1, pandoc.RawBlock('latex', '\\begin{'..type..'}'))
    result:insert(pandoc.RawBlock('latex', '\\end{'..type..'}'))
    return pandoc.Div(result)
end

-- Takes list items and inserts \ex\label{}.
-- I hate this function
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

--------------------
--- Ref function ---
--------------------
-- Replace <&labels>
function Str(element)
    if string.match(element.text, "<%&([%s%w%-:]+)>") then
        local label, punc = string.match(element.text, "<%&([%s%w%-:]+)>(%p*)")
        if punc==nil then
            punc = ""
        end
        if FORMAT:match 'latex' then
            return pandoc.RawInline("latex", "(\\ref{"..label.."})"..punc)
        elseif FORMAT:match 'html' then
            return pandoc.RawInline('html', '<a id='..label..'-ref href=#'..label..'-label>(here)</a>')
        end
    else
        return element
    end
end
