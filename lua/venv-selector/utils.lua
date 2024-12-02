local M = {}

function M.table_has_content(t)
    return next(t) ~= nil
end

-- split a string
function M.split_string(str)
    local result = {}
    local buffer = ""
    local in_quotes = false
    local quote_char = nil
    local i = 1

    while i <= #str do
        local c = str:sub(i, i)
        if c == "'" or c == '"' then
            if in_quotes then
                if c == quote_char then
                    in_quotes = false
                    quote_char = nil
                    -- Do not include the closing quote
                else
                    buffer = buffer .. c
                end
            else
                in_quotes = true
                quote_char = c
                -- Do not include the opening quote
            end
        elseif c == " " then
            if in_quotes then
                buffer = buffer .. c
            else
                if #buffer > 0 then
                    table.insert(result, buffer)
                    buffer = ""
                end
            end
        else
            buffer = buffer .. c
        end
        i = i + 1
    end

    if #buffer > 0 then
        table.insert(result, buffer)
    end

    return result
end

return M
