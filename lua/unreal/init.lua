local M = {}

function M.setup(options)
  -- Default options
  local default_options = {
    -- Add your default options here
    logging = {
      level = "info",
      path = vim.fn.stdpath("data") .. "/unreal.log",
    },
  }

  -- Merge user-provided options with default options
  options = vim.tbl_deep_extend("force", default_options, options or {})

  -- Use the merged options to configure the plugin
  -- For example:
  -- require("unreal.logging").setup(options.logging)
  -- require("unreal.core").setup(options)
end

return M
