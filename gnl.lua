-- Functions specific to me and how I work

-- Puts my comments in the gnl tag.
function Span(element)
    if element.classes[1] == "gnl" then
        table.insert(element.content, 1, pandoc.RawInline('latex', '\\gnl{'))
        table.insert(element.content, pandoc.RawInline('latex', '}'))
    end
    return element
end
