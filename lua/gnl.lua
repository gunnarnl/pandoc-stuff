-- Functions specific to me and how I work

-- Puts my comments in the gnl tag.
function Span(element)
    if element.classes[1] == "gnl" then
        table.insert(element.content, 1, pandoc.RawInline('latex', '\\gnl{'))
        table.insert(element.content, pandoc.RawInline('latex', '}'))
    end
    return element
end

-- Insert LaTeX at header of references to enforce hanging indents.
function Div(element)
    if element.identifier == "refs" then
        table.insert(element.content, 1, pandoc.RawBlock('latex','\\setlength{\\parindent}{-1.24cm}\\setlength{\\leftskip}{1.24cm}\\setlength{\\parskip}{8pt}\\noindent'))
    end
    return element
end
