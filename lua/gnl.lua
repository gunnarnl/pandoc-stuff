-- Functions specific to me and how I work

-- Puts my comments in the gnl tag.
function Span(element)
    if element.classes[1] == "gnl" and FORMAT:match 'latex' then
        table.insert(element.content, 1, pandoc.RawInline('latex', '\\gnl{'))
        table.insert(element.content, pandoc.RawInline('latex', '}'))
    elseif element.classes[1] == "evfxn" then
        table.insert(element.content, 1, pandoc.Str('⟦'))
        table.insert(element.content, pandoc.Str('⟧'))
    end
    return element
end

-- Insert LaTeX at header of references to enforce hanging indents.
function Div(element)
    if FORMAT:match 'latex' then
        if element.identifier == "refs" then
            table.insert(element.content, 1, pandoc.RawBlock('latex','\\setlength{\\parindent}{-1.24cm}\\setlength{\\leftskip}{1.24cm}\\setlength{\\parskip}{8pt}\\noindent'))
        end
        return element
    elseif FORMAT:match 'html' then
        return element --Not sure what to do here yet.
    else
        return element
    end
end
