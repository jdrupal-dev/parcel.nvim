local M = {}

M.enabled = false

M.setup = function(options)
  require("parcel.config").__setup(options)
  M.enabled = require("parcel.config").options.default_enabled

  if M.enabled then
    require("parcel.outdated_packages").setup()
  end

  vim.api.nvim_create_user_command("ParcelToggle", function()
    M.enabled = not M.enabled
    require("parcel.outdated_packages").setup()
  end, {})
end

return M
