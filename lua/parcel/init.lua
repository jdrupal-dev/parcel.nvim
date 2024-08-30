local M = {}

M.enabled = false

M.setup = function(options)
  require("parcel.config").__setup(options)
  M.enabled = require("parcel.config").options.default_enabled

  require("parcel.outdated_packages").setup()
  vim.api.nvim_create_user_command("ParcelToggle", function()
    M.enabled = not M.enabled
    require("parcel.outdated_packages").setup()
  end, {})
end

return M
