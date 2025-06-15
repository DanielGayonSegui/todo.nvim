local M = {}

local win = nil

local default_opts = {
	target_file = "~/notes/todo.md",
	border = "rounded",
}

local function expand_path(path)
  if path:sub(1, 1) == "~" then
    return os.getenv("HOME") .. path:sub(2)
  end
  return path
end

local function win_config(opts)
  local width = math.min(math.floor(vim.o.columns * 0.8), 80)
  local height = math.floor(vim.o.lines * 0.8)
  return {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = opts.border,
  }
end

local function open_floating_file(opts)
  if win ~= nil and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_set_current_win(win)
		return
	end
  
  local expanded_path = expand_path(opts.target_file)

  if vim.fn.filereadable(expanded_path) == 0 then
    vim.notify("File not found: " .. expanded_path, vim.log.levels.ERROR)
    return
  end

  local buf = vim.fn.bufnr(expanded_path, true)

  if buf == -1 then
    buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(buf, expanded_path)
  end

  vim.bo[buf].swapfile = false

  win = vim.api.nvim_open_win(buf, true, win_config(opts))

  vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
    noremap = true,
    silent = true,
    callback = function()
      if vim.api.nvim_get_option_value("modified", { buf = buf }) then
        vim.notify("Unsaved changes, close anyway?", vim.log.levels.WARN)
      else
        vim.api.nvim_win_close(0, true)
        win = nil
      end
    end,
  })
end

local function setup_user_commands(opts)
  opts = vim.tbl_deep_extend("force", default_opts, opts)
  vim.api.nvim_create_user_command("Td", function()
    open_floating_file(opts)
  end, {})
end

M.setup = function(opts)
  setup_user_commands(opts)
end

return M
