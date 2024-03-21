local M = {}

M.get_file_prefix = function(integration)
  return integration .. vim.loop.cwd():gsub("/", "-")
end

M.current_dir = function()
  local path = vim.api.nvim_buf_get_name(0)
  return path:match("(.*/)")
end

return M
