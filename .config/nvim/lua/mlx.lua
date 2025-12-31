local function chat_with_mlx()
    local input = vim.api.nvim_get_current_line()
    vim.cmd('vnew | setlocal buftype=nofile bufhidden=hide noswapfile ft=markdown')
    local bufnr = vim.api.nvim_get_current_buf()

    -- Ensure we escape the input properly for the shell
    local payload = vim.fn.json_encode({
        messages = {{role = "user", content = input}},
        stream = true
    })

    local cmd = {
        "curl", "-s", "-N", "http://127.0.0.1:8080/v1/chat/completions",
        "-H", "Content-Type: application/json",
        "-d", payload
    }

    vim.fn.jobstart(cmd, {
        on_stdout = function(_, data)
            if not data then return end
            
            for _, line in ipairs(data) do
                -- MLX server sends lines starting with "data: {"
                if line:match("^data: ") then
                    local json_str = line:gsub("^data: ", "")
                    
                    -- Check if it's the end of the stream
                    if json_str:match("%[DONE%]") then return end

                    -- Safely decode the JSON to get the content
                    local ok, decoded = pcall(vim.fn.json_decode, json_str)
                    if ok and decoded.choices and decoded.choices[1].delta.content then
                        local content = decoded.choices[1].delta.content
                        -- Append the text to the end of the buffer
                        local last_line = vim.api.nvim_buf_get_lines(bufnr, -2, -1, false)[1] or ""
                        local new_lines = vim.split(content, "\n")
                        
                        -- Merge the first new piece with the current last line
                        new_lines[1] = last_line .. new_lines[1]
                        vim.api.nvim_buf_set_lines(bufnr, -2, -1, false, new_lines)
                    end
                end
            end
        end,
        on_stderr = function(_, data)
             if data and #data[1] > 0 then print("Error: " .. table.concat(data, "\n")) end
        end
    })
end

vim.api.nvim_create_user_command('MLX', chat_with_mlx, {})
