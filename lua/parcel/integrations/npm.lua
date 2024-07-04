local M = {
  dependency_file_pattern = "package.json",
}

M.get_outdated_packages = function(file_path, force_update)
  local cache = "/tmp/outdated-packages" .. file_path:gsub("/", "-")
  local exists = vim.loop.fs_stat(cache)

  local result
  if exists then
    local content = vim.fn.readfile(cache)
    if next(content) ~= nil then
      result = vim.fn.json_decode(content)
    end
  end

  if not exists or force_update then
    vim.fn.jobstart("npm outdated --json > " .. cache, {
      cwd = file_path:match("(.*/)"),
      on_exit = function()
        print("Fetched outdated node modules.")
        M.show_new_version(file_path, false)
      end,
    })
  end

  return result
end

M.get_package_list = function(file_path, force_update)
  local cache = "/tmp/packages" .. file_path:gsub("/", "-")
  local exists = vim.loop.fs_stat(cache)

  local result
  if exists then
    local content = vim.fn.readfile(cache)
    if next(content) ~= nil then
      result = vim.fn.json_decode(content)
    end
  end

  if not exists or force_update then
    vim.fn.jobstart("npm list --json --package-lock-only > " .. cache, {
      cwd = file_path:match("(.*/)"),
      on_exit = function()
        print("Fetched node module versions.")
        M.show_current_version(file_path, false)
      end,
    })
  end

  return result
end

M.show_current_version = function(file_path, force_update)
  local package_info = M.get_package_list(file_path, force_update)
  if not package_info or not package_info.dependencies then
    return
  end

  local namespace = vim.api.nvim_create_namespace("npm-current-version")
  vim.api.nvim_buf_clear_namespace(0, namespace, 1, -1)

  -- jsonpath requires us to modify the cursor, we store it so that we can
  -- revert to the original cursor position after adding the extmarks.
  local original_cursor = vim.api.nvim_win_get_cursor(0)
  for line_number, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, true)) do
    vim.api.nvim_win_set_cursor(0, { line_number, #line - 1 })
    local path = require("jsonpath").get()
    if path:find("^%.dependencies") ~= nil or path:find("^%.devDependencies") ~= nil then
      local package_name = line:match('"([^"]+)"')
      local info = package_info.dependencies[package_name]
      if info ~= nil then
        local text = {}
        if info.version then
          text = { { "installed: " .. info.version, "Comment" } }
        end

        vim.api.nvim_buf_set_extmark(0, namespace, line_number - 1, 0, {
          virt_text = text,
          right_gravity = false,
        })
      end
    end
  end
  vim.api.nvim_win_set_cursor(0, original_cursor)
end

M.show_new_version = function(file_path, force_update)
  local package_info = M.get_outdated_packages(file_path, force_update)
  if not package_info then
    return
  end

  local namespace = vim.api.nvim_create_namespace("npm-new-version")
  vim.api.nvim_buf_clear_namespace(0, namespace, 1, -1)

  -- jsonpath requires us to modify the cursor, we store it so that we can
  -- revert to the original cursor position after adding the extmarks.
  local original_cursor = vim.api.nvim_win_get_cursor(0)
  for line_number, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, true)) do
    vim.api.nvim_win_set_cursor(0, { line_number, #line - 1 })
    local path = require("jsonpath").get()
    if path:find("^%.dependencies") ~= nil or path:find("^%.devDependencies") ~= nil then
      local package_name = line:match('"([^"]+)"')
      local info = package_info[package_name]
      if info ~= nil then
        local text = { { "| minor: ", "Comment" }, { info.wanted, "warningMsg" } }
        if info.wanted == info.current then
          text = { { "| major: ", "Comment" }, { info.latest, "errorMsg" } }
        elseif info.wanted ~= info.latest then
          table.insert(text, { " | major: ", "Comment" })
          table.insert(text, { info.latest, "errorMsg" })
        end

        vim.api.nvim_buf_set_extmark(0, namespace, line_number - 1, 0, {
          virt_text = text,
        })
      end
    end
  end
  vim.api.nvim_win_set_cursor(0, original_cursor)
end

return M
