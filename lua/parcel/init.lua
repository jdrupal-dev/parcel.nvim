local M = {}

M.setup = function(options)
  require("parcel.config").__setup(options)

  require("parcel.outdated_packages").setup()
end

return M
