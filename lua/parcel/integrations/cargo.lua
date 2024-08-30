local M = {
  dependency_file_pattern = "Cargo.toml",
}

M.get_package_list = function(file_path, force_update) end

M.show_current_version = function(file_path, force_update) end

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
    vim.fn.jobstart("cargo outdated --format=json --root-deps-only > " .. cache, {
      cwd = file_path:match("(.*/)"),
      on_exit = function()
        print("Fetched outdated crates.")
        M.show_new_version(file_path, false)
      end,
    })
  end

  return result
end

M.show_new_version = function(file_path, force_update)
  local outdated = M.get_outdated_packages(file_path, force_update)
  if not outdated then
    return
  end

  local package_info = {}
  for _, item in ipairs(outdated.dependencies) do
    if item.name ~= nil then
      package_info[item.name] = item
    end
  end

  local namespace = vim.api.nvim_create_namespace("cargo-new-version")
  vim.api.nvim_buf_clear_namespace(0, namespace, 1, -1)

  local is_dependencies = false
  for line_number, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, true)) do
    vim.api.nvim_win_set_cursor(0, { line_number, #line })
    if line:find("^%[dependencies%]") ~= nil then
      is_dependencies = true
    elseif line:find("^%[.*%]") ~= nil then
      is_dependencies = false
    end

    if is_dependencies then
      local package_name = line:match("^([^ ]+) =")
      local info = package_info[package_name]
      if info ~= nil then
        local text = { { "minor: ", "Comment" }, { info.compat, "warningMsg" } }
        if info.compat == info.current then
          text = { { "major: ", "Comment" }, { info.latest, "errorMsg" } }
        elseif info.compat ~= info.latest then
          table.insert(text, { " | major: ", "Comment" })
          table.insert(text, { info.latest, "errorMsg" })
        end

        vim.api.nvim_buf_set_extmark(0, namespace, line_number - 1, 0, {
          virt_text = text,
        })
      end
    end
  end
end

M.clear_namespaces = function()
  vim.api.nvim_buf_clear_namespace(0, vim.api.nvim_create_namespace("cargo-new-version"), 1, -1)
end

return M
