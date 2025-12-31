local function get_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local start_col = start_pos[3]
  local end_line = end_pos[2]
  local end_col = end_pos[3]

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    return nil
  end

  if start_line == end_line then
    return lines[1]:sub(start_col, end_col)
  end

  local result = {}
  for i, line in ipairs(lines) do
    if i == 1 then
      table.insert(result, line:sub(start_col))
    elseif i == #lines then
      table.insert(result, line:sub(1, end_col))
    else
      table.insert(result, line)
    end
  end

  return table.concat(result, '\n')
end

local function chat_with_mlx()
    ---local input = vim.api.nvim_get_current_line()
    local input = get_selection()
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

vim.api.nvim_create_user_command('MLX', chat_with_mlx, { range = true })
vim.keymap.set("x", "am", ":MLX<CR>", { desc = "Execute MLX command" })
