-- TODO: standardize single quotes
-- NOTE: Gloss support in HTML may be buggy right now. Need to test it more.

local List = require 'pandoc.List'

---------------------------------
--- Main OrderedList function ---
---------------------------------
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

-- Handles sublists.
function sublists(element, num)
    return pandoc.walk_block(element, {
        OrderedList = function(ele)
            if ele.style ~= "Example" then
                if FORMAT:match 'html' then
                    return html_labels(ele, num)
                elseif FORMAT:match 'latex' then
                    return ins_gb4e_span(ele, 'xlist')
                end
            end
        end
    })
end

----------------------
--- Html functions ---
----------------------
-- Main function
function html_rules(element)
    local startnum = element.start
    element = sublists(element, num)
    element = html_labels(element, startnum)
    return element
end

-- Remove md labels and insert anchors.
function html_labels(element, num)
    local result = List:new()
    for j, li in pairs(element.content) do
        local label, gloss, li = get_label(li)
        li = insert_html_anchor(li, label, num)
        if gloss == true then
            li = html_gloss(li)
        end
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

-- Glosses
function html_gloss(li)
    raw_inlines = List:new(li[1].content)
    link, lind  = raw_inlines:find_if(function(x) return x.t=='RawInline' end)
    raw_inlines:remove(lind) -- Remove link
    raw_inlines:remove(lind) -- Remove blank Str
    local result = List:new()
    local counter = 1
    local transPos = 0
    local textinlines = List:new({'Str', 'SmallCaps', 'Emph', 'Strikeout', 'Strong', 'Quoted', 'RawInline', 'Math', 'Span', 'SoftBreak'}) --SoftBreak included as delimiter
    result:insert(link)
    result:insert(pandoc.RawInline('html', '<table class="ilg">'))
    result:insert(pandoc.RawInline('html', '<tr>'))
    for i, item in pairs(raw_inlines:filter(get_text_inlines(textinlines))) do
        if item.t == "SoftBreak" then
            --counter = counter + 1
            if counter == 2 then
                result:insert(pandoc.RawInline('html', '</tr><tr><td colspan=100 class="trans">'))
            else
                result:insert(pandoc.RawInline('html', '</tr><tr>'))
            end
            counter = counter + 1
        elseif counter < 3 then
            result:insert(pandoc.RawInline('html', '<td>'))
            print (item.t)
            result:insert(item)
            result:insert(pandoc.RawInline('html', '</td>'))
        elseif counter == 3 then
            result:insert(item)
        end
    end
    result:insert(pandoc.RawInline('html', '</td></tr></table>'))
    li[1].content = result
    return li
end

function get_text_inlines(textinlines)
    return function(x) return textinlines:includes(x.t) end
end

-----------------------
--- Latex functions ---
-----------------------
-- Main function
function latex_rules(element)
    startnum = element.start -- Currently not used.
    element = sublists(element, num) -- Inserts xlist tags.
    return ins_gb4e_span(element, 'exe')
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
