local M = {
  dependency_file_pattern = "composer.json",
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
    vim.fn.jobstart("composer outdated --locked --format=json > " .. cache, {
      cwd = file_path:match("(.*/)"),
      on_exit = function()
        print("Fetched outdated composer packages.")
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
    vim.fn.jobstart("composer show -i --format=json > " .. cache, {
      cwd = file_path:match("(.*/)"),
      on_exit = function()
        print("Fetched composer package versions.")
        M.show_current_version(file_path, false)
      end,
    })
  end

  return result
end

M.show_current_version = function(file_path, force_update)
  local installed = M.get_package_list(file_path, force_update)
  if not installed or not installed.installed then
    return
  end

  local package_info = {}
  for _, item in ipairs(installed.installed) do
    if item.name ~= nil then
      package_info[item.name] = item
    end
  end

  local namespace = vim.api.nvim_create_namespace("composer-current-version")
  vim.api.nvim_buf_clear_namespace(0, namespace, 1, -1)

  -- jsonpath requires us to modify the cursor, we store it so that we can
  -- revert to the original cursor position after adding the extmarks.
  local original_cursor = vim.api.nvim_win_get_cursor(0)
  local current_audit = nil
  for line_number, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, true)) do
    vim.api.nvim_win_set_cursor(0, { line_number, #line - 1 })
    local path = require("jsonpath").get()

    -- Render current audit if the path has changed.
    if current_audit and path:find(current_audit.path) == nil then
      vim.api.nvim_buf_set_extmark(0, namespace, current_audit.line - 1, 0, {
        virt_text = { { "total: " .. current_audit.total, "Comment" } },
        right_gravity = false,
      })
      current_audit = nil
    end

    if path:find("^%.require") ~= nil or path:find('^%.%["require-dev') ~= nil then
      if current_audit == nil then
        current_audit = {
          total = 0,
          line = line_number,
          path = path,
        }
      end
      local package_name = line:match('"([^"]+)"')
      local info = package_info[package_name]
      if info ~= nil then
        local text = { { "installed: " .. info.version, "Comment" } }

        current_audit.total = current_audit.total + 1
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
  local outdated = M.get_outdated_packages(file_path, force_update)
  if not outdated then
    return
  end

  local package_info = {}
  for _, item in ipairs(outdated.locked) do
    if item.name ~= nil then
      package_info[item.name] = item
    end
  end

  local namespace = vim.api.nvim_create_namespace("composer-new-version")
  vim.api.nvim_buf_clear_namespace(0, namespace, 1, -1)

  -- jsonpath requires us to modify the cursor, we store it so that we can
  -- revert to the original cursor position after adding the extmarks.
  local original_cursor = vim.api.nvim_win_get_cursor(0)
  local current_audit = nil
  for line_number, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, true)) do
    vim.api.nvim_win_set_cursor(0, { line_number, #line - 1 })
    local path = require("jsonpath").get()

    -- Render current audit if the path has changed.
    if current_audit and path:find(current_audit.path) == nil then
      local audit_text = {}
      if current_audit.minor > 0 then
        table.insert(audit_text, { "| minor: ", "Comment" })
        -- Convert number to string.
        table.insert(audit_text, { current_audit.minor .. "", "warningMsg" })
      end
      if current_audit.major > 0 then
        table.insert(audit_text, { " | major: ", "Comment" })
        -- Convert number to string.
        table.insert(audit_text, { current_audit.major .. "", "errorMsg" })
      end
      vim.api.nvim_buf_set_extmark(0, namespace, current_audit.line - 1, 0, {
        virt_text = audit_text,
      })
      current_audit = nil
    end

    if path:find("^%.require") ~= nil or path:find('^%.%["require-dev') ~= nil then
      if current_audit == nil then
        current_audit = {
          major = 0,
          minor = 0,
          line = line_number,
          path = path,
        }
      end

      local package_name = line:match('"([^"]+)"')
      local info = package_info[package_name]
      if info ~= nil then
        local text = {}
        if info["latest-status"] == "update-possible" then
          current_audit.major = current_audit.major + 1
          text = { { "| major: ", "Comment" }, { info.latest, "errorMsg" } }
        elseif info["latest-status"] == "semver-safe-update" then
          current_audit.minor = current_audit.minor + 1
          text = { { "| minor: ", "Comment" }, { info.latest, "warningMsg" } }
        end

        if text then
          vim.api.nvim_buf_set_extmark(0, namespace, line_number - 1, 0, {
            virt_text = text,
          })
        end
      end
    end
  end
  vim.api.nvim_win_set_cursor(0, original_cursor)
end

M.clear_namespaces = function()
  vim.api.nvim_buf_clear_namespace(0, vim.api.nvim_create_namespace("composer-new-version"), 1, -1)
  vim.api.nvim_buf_clear_namespace(0, vim.api.nvim_create_namespace("composer-current-version"), 1, -1)
end

return M
