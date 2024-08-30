local M = {}

local toggle_integration = function(integration)
  if require("parcel").enabled then
    integration.show_current_version(vim.api.nvim_buf_get_name(0), false)
    integration.show_new_version(vim.api.nvim_buf_get_name(0), false)
  else
    integration.clear_namespaces()
  end
end

M.setup = function()
  for _, integration in pairs(require("parcel.integrations")) do
    local root_file = vim.loop.cwd() .. "/" .. integration.dependency_file_pattern
    if vim.loop.fs_stat(root_file) then
      integration.get_package_list(root_file)
      integration.get_outdated_packages(root_file)
    end

    if vim.fn.expand("%") == integration.dependency_file_pattern then
      toggle_integration(integration)
    end

    vim.api.nvim_create_autocmd("BufRead", {
      pattern = integration.dependency_file_pattern,
      callback = function()
        toggle_integration(integration)
      end,
    })
  end
end

return M
