local M = {}

M.setup = function()
  for _, integration in pairs(require("parcel.integrations")) do
    local root_file = vim.loop.cwd() .. "/" .. integration.dependency_file_pattern
    if vim.loop.fs_stat(root_file) then
      integration.get_package_list(root_file)
      integration.get_outdated_packages(root_file)
    end

    vim.api.nvim_create_autocmd("BufRead", {
      pattern = integration.dependency_file_pattern,
      callback = function()
        integration.show_current_version(vim.api.nvim_buf_get_name(0), true)
        integration.show_new_version(vim.api.nvim_buf_get_name(0), true)
      end,
    })
  end
end

return M
