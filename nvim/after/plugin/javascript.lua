-- JavaScript/TypeScript Development Configuration for Neovim
-- Author: Joshua Michael Hall
-- GitHub: joshuamichaelhall
-- 
-- This configuration sets up Neovim for JavaScript/TypeScript development with:
-- - LSP support via TypeScript Language Server
-- - ESLint for linting
-- - Prettier for formatting
-- - Jest for testing
-- - React/Vue/Angular-specific functionality
-- - Debugging via DAP

-- Load required modules
local lspconfig = require('lspconfig')
local null_ls = require('null-ls')

-- Configure TypeScript language server
lspconfig.tsserver.setup {
  filetypes = { 
    "javascript", 
    "javascriptreact", 
    "javascript.jsx", 
    "typescript", 
    "typescriptreact", 
    "typescript.tsx" 
  },
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
      format = {
        indentSize = 2,
        convertTabsToSpaces = true,
        tabSize = 2,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
      format = {
        indentSize = 2,
        convertTabsToSpaces = true,
        tabSize = 2,
      },
    },
    completions = {
      completeFunctionCalls = true,
    },
  },
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
}

-- Configure ESLint
lspconfig.eslint.setup {
  filetypes = { 
    "javascript", 
    "javascriptreact", 
    "javascript.jsx", 
    "typescript", 
    "typescriptreact", 
    "typescript.tsx",
    "vue",
    "svelte",
  },
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
  settings = {
    codeAction = {
      disableRuleComment = {
        enable = true,
        location = "separateLine"
      },
      showDocumentation = {
        enable = true
      }
    },
    codeActionOnSave = {
      enable = true,
      mode = "all"
    },
    format = true,
    nodePath = "",
    onIgnoredFiles = "off",
    packageManager = "npm",
    quiet = false,
    rulesCustomizations = {},
    run = "onType",
    useESLintClass = false,
    validate = "on",
    workingDirectory = {
      mode = "auto"
    }
  }
}

-- Configure optional Vue language server
pcall(function()
  lspconfig.volar.setup {
    filetypes = {'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'json'},
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
  }
end)

-- Configure optional Angular language server
pcall(function()
  lspconfig.angularls.setup {
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
  }
end)

-- Setup Prettier and ESLint with null-ls
null_ls.setup({
  sources = {
    -- Prettier
    null_ls.builtins.formatting.prettier.with({
      filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "css",
        "scss",
        "less",
        "html",
        "json",
        "yaml",
        "markdown",
        "graphql",
        "svelte",
      },
      prefer_local = "node_modules/.bin",
      extra_args = {"--single-quote", "--jsx-single-quote"},
    }),
    -- ESLint
    null_ls.builtins.diagnostics.eslint.with({
      prefer_local = "node_modules/.bin",
    }),
    null_ls.builtins.code_actions.eslint.with({
      prefer_local = "node_modules/.bin",
    }),
    null_ls.builtins.formatting.eslint.with({
      prefer_local = "node_modules/.bin",
    }),
  },
})

-- Detect project type
local function detect_project_type()
  -- Check for package.json
  if vim.fn.filereadable("package.json") == 1 then
    local package_content = vim.fn.readfile("package.json")
    local package_json = vim.fn.json_decode(table.concat(package_content, "\n"))
    
    -- Check for dependencies
    local deps = {}
    if package_json.dependencies then
      for k, _ in pairs(package_json.dependencies) do
        deps[k] = true
      end
    end
    if package_json.devDependencies then
      for k, _ in pairs(package_json.devDependencies) do
        deps[k] = true
      end
    end
    
    -- Detect framework
    if deps["react"] then
      return "react"
    elseif deps["vue"] then
      return "vue"
    elseif deps["@angular/core"] then
      return "angular"
    elseif deps["svelte"] then
      return "svelte"
    elseif deps["next"] then
      return "next"
    elseif deps["express"] or deps["fastify"] or deps["koa"] or deps["hapi"] then
      return "node"
    end
  end
  
  -- Check for specific files
  if vim.fn.filereadable("angular.json") == 1 then
    return "angular"
  elseif vim.fn.filereadable("next.config.js") == 1 then
    return "next"
  elseif vim.fn.filereadable("nuxt.config.js") == 1 or vim.fn.filereadable("nuxt.config.ts") == 1 then
    return "nuxt"
  end
  
  return "javascript"
end

-- Setup debugging
local dap = require('dap')

-- Node.js debugging
dap.adapters.node2 = {
  type = 'executable',
  command = 'node',
  args = {vim.fn.stdpath('data') .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js'},
}

-- Chrome debugging
dap.adapters.chrome = {
  type = 'executable',
  command = 'node',
  args = {vim.fn.stdpath('data') .. '/mason/packages/chrome-debug-adapter/out/src/chromeDebug.js'},
}

-- Add configurations based on project type
local project_type = detect_project_type()

-- Default Node.js configuration
dap.configurations.javascript = {
  {
    name = 'Launch',
    type = 'node2',
    request = 'launch',
    program = '${file}',
    cwd = vim.fn.getcwd(),
    sourceMaps = true,
    protocol = 'inspector',
    console = 'integratedTerminal',
  },
  {
    name = 'Attach to process',
    type = 'node2',
    request = 'attach',
    processId = require('dap.utils').pick_process,
  },
}
dap.configurations.typescript = dap.configurations.javascript

-- Add browser debugging for frontend projects
if project_type == "react" or project_type == "vue" or project_type == "svelte" or project_type == "angular" or project_type == "next" or project_type == "nuxt" then
  table.insert(dap.configurations.javascript, {
    name = 'Debug Web Application',
    type = 'chrome',
    request = 'launch',
    url = 'http://localhost:3000',
    webRoot = '${workspaceFolder}',
    userDataDir = '${workspaceFolder}/.vscode/chrome-debug-user-data',
    sourceMaps = true,
  })
  
  table.insert(dap.configurations.typescript, {
    name = 'Debug Web Application',
    type = 'chrome',
    request = 'launch',
    url = 'http://localhost:3000',
    webRoot = '${workspaceFolder}',
    userDataDir = '${workspaceFolder}/.vscode/chrome-debug-user-data',
    sourceMaps = true,
  })
  
  -- Add Jest debugging
  table.insert(dap.configurations.javascript, {
    type = 'node2',
    request = 'launch',
    name = 'Debug Jest Tests',
    program = '${workspaceFolder}/node_modules/.bin/jest',
    args = {'--runInBand'},
    console = 'integratedTerminal',
    internalConsoleOptions = 'neverOpen',
    disableOptimisticBPs = true,
  })
end

-- JavaScript/TypeScript specific keymaps
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact", "vue", "svelte" },
  callback = function()
    local opts = { buffer = true, silent = true }
    
    -- Format current file
    vim.keymap.set("n", "<leader>jf", function()
      vim.lsp.buf.format()
    end, { buffer = true, desc = "Format JS/TS file" })
    
    -- Run with Node
    vim.keymap.set("n", "<leader>jr", ":w<CR>:sp<CR>:term node %<CR>", 
      { buffer = true, desc = "Run with Node" })
    
    -- Run tests
    vim.keymap.set("n", "<leader>jt", function()
      local cmd = ""
      if vim.fn.filereadable("package.json") == 1 then
        -- Check if package.json contains test script
        local package_content = vim.fn.readfile("package.json")
        local package_json = vim.fn.json_decode(table.concat(package_content, "\n"))
        
        if package_json.scripts and package_json.scripts.test then
          cmd = "npm test"
        elseif vim.fn.filereadable("node_modules/.bin/jest") == 1 then
          cmd = "node_modules/.bin/jest"
        else
          cmd = "npx jest"
        end
      else
        cmd = "npx jest"
      end
      
      vim.cmd(":w<CR>:sp<CR>:term " .. cmd .. "<CR>")
    end, { buffer = true, desc = "Run tests" })
    
    -- Run test file
    vim.keymap.set("n", "<leader>jT", function()
      local file = vim.fn.expand("%")
      local cmd = ""
      
      if vim.fn.filereadable("node_modules/.bin/jest") == 1 then
        cmd = "node_modules/.bin/jest " .. file
      else
        cmd = "npx jest " .. file
      end
      
      vim.cmd(":w<CR>:sp<CR>:term " .. cmd .. "<CR>")
    end, { buffer = true, desc = "Run test file" })
    
    -- Debug current file
    vim.keymap.set("n", "<leader>jd", function()
      require('dap').continue()
    end, { buffer = true, desc = "Debug current file" })
    
    -- NPM commands
    vim.keymap.set("n", "<leader>ji", ":!npm install<CR>", 
      { buffer = true, desc = "npm install" })
    
    vim.keymap.set("n", "<leader>js", function()
      local cmd = ""
      if vim.fn.filereadable("package.json") == 1 then
        -- Check if package.json contains start script
        local package_content = vim.fn.readfile("package.json")
        local package_json = vim.fn.json_decode(table.concat(package_content, "\n"))
        
        if package_json.scripts and package_json.scripts.dev then
          cmd = "npm run dev"
        elseif package_json.scripts and package_json.scripts.start then
          cmd = "npm start"
        elseif package_json.scripts and package_json.scripts.serve then
          cmd = "npm run serve"
        else
          cmd = "npm start"
        end
      else
        cmd = "npm start"
      end
      
      vim.cmd(":sp<CR>:term " .. cmd .. "<CR>")
    end, { buffer = true, desc = "Start application" })
    
    -- Import helpers
    vim.keymap.set("n", "<leader>ji", function()
      local word = vim.fn.expand("<cword>")
      local line_num = vim.fn.line(".")
      local import_line = "import " .. word .. " from './';"
      
      vim.api.nvim_buf_set_lines(0, line_num - 1, line_num - 1, false, {import_line})
      vim.cmd("normal! " .. line_num .. "G$F/")
    end, { buffer = true, desc = "Quick import" })
    
    -- Insert console.log for current word
    vim.keymap.set("n", "<leader>jc", function()
      local word = vim.fn.expand("<cword>")
      local line_num = vim.fn.line(".")
      local log_line = "console.log('" .. word .. ":', " .. word .. ");"
      
      vim.api.nvim_buf_set_lines(0, line_num, line_num, false, {log_line})
      vim.cmd("normal! j==")
    end, { buffer = true, desc = "Console log variable" })
    
    -- Framework-specific keybindings
    if project_type == "react" then
      -- Create new component
      vim.keymap.set("n", "<leader>jrn", function()
        vim.ui.input({ prompt = "Component name: " }, function(input)
          if input then
            local component_name = input
            local first_letter = string.sub(component_name, 1, 1)
            local rest = string.sub(component_name, 2)
            local capitalized = string.upper(first_letter) .. rest
            
            vim.cmd("e " .. capitalized .. ".jsx")
            
            local template = {
              "import React from 'react';",
              "",
              "const " .. capitalized .. " = (props) => {",
              "  return (",
              "    <>",
              "      ",
              "    </>",
              "  );",
              "};",
              "",
              "export default " .. capitalized .. ";",
              "",
            }
            
            vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
            vim.cmd("normal! 6G$")
          end
        end)
      end, { buffer = true, desc = "New React component" })
    elseif project_type == "vue" then
      -- Create new component
      vim.keymap.set("n", "<leader>jvn", function()
        vim.ui.input({ prompt = "Component name: " }, function(input)
          if input then
            local component_name = input
            
            vim.cmd("e " .. component_name .. ".vue")
            
            local template = {
              "<template>",
              "  ",
              "</template>",
              "",
              "<script>",
              "export default {",
              "  name: '" .. component_name .. "',",
              "  props: {",
              "  },",
              "  data() {",
              "    return {",
              "    };",
              "  },",
              "  methods: {",
              "  }",
              "};",
              "</script>",
              "",
              "<style scoped>",
              "",
              "</style>",
              "",
            }
            
            vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
            vim.cmd("normal! 2G$")
          end
        end)
      end, { buffer = true, desc = "New Vue component" })
    end
  end,
})

-- Setup file templates
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
  callback = function()
    local filename = vim.fn.expand("%:t")
    local ext = vim.fn.expand("%:e")
    local is_typescript = ext == "ts" or ext == "tsx"
    local is_react = ext == "jsx" or ext == "tsx"
    
    -- React component template
    if is_react and not filename:match("%.test%.") and not filename:match("%.spec%.") then
      local component_name = filename:gsub("%.[^.]+$", "")
      
      local template = {}
      if is_typescript then
        table.insert(template, 'import React, { FC } from "react";')
        table.insert(template, "")
        table.insert(template, "interface " .. component_name .. "Props {")
        table.insert(template, "  // Define props here")
        table.insert(template, "}")
        table.insert(template, "")
        table.insert(template, "const " .. component_name .. ": FC<" .. component_name .. "Props> = (props) => {")
      else
        table.insert(template, 'import React from "react";')
        table.insert(template, "")
        table.insert(template, "const " .. component_name .. " = (props) => {")
      end
      
      table.insert(template, "  return (")
      table.insert(template, "    <>")
      table.insert(template, "      ")
      table.insert(template, "    </>")
      table.insert(template, "  );")
      table.insert(template, "};")
      table.insert(template, "")
      table.insert(template, "export default " .. component_name .. ";")
      table.insert(template, "")
      
      vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
      
      -- Position cursor inside the component
      if is_typescript then
        vim.cmd("normal! 9G$")
      else
        vim.cmd("normal! 7G$")
      end
    -- TypeScript file template
    elseif is_typescript and not filename:match("%.test%.") and not filename:match("%.spec%.") then
      local template = {
        "/**",
        " * " .. filename,
        " */",
        "",
        "",
        "export {};",
        "",
      }
      
      vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
      vim.cmd("normal! 5G$")
    -- JavaScript file template
    elseif not filename:match("%.test%.") and not filename:match("%.spec%.") then
      local template = {
        "/**",
        " * " .. filename,
        " */",
        "",
        "",
        "",
      }
      
      vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
      vim.cmd("normal! 5G$")
    -- Test file template
    else
      local base_name = filename:gsub("%.test%.", "."):gsub("%.spec%.", ".")
      local import_name = base_name:gsub("%.[^.]+$", "")
      
      local template = {}
      
      if filename:match("%.test%.") then
        -- Jest tests
        if is_typescript then
          table.insert(template, 'import ' .. import_name .. ' from "./' .. import_name .. '";')
        else
          table.insert(template, 'import ' .. import_name .. ' from "./' .. import_name .. '";')
        end
        
        table.insert(template, "")
        table.insert(template, 'describe("' .. import_name .. '", () => {')
        table.insert(template, '  test("should work correctly", () => {')
        table.insert(template, "    // Arrange")
        table.insert(template, "    ")
        table.insert(template, "    // Act")
        table.insert(template, "    ")
        table.insert(template, "    // Assert")
        table.insert(template, "    expect(true).toBe(true);")
        table.insert(template, "  });")
        table.insert(template, "});")
        table.insert(template, "")
        
        vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
        vim.cmd("normal! 6G$")
      end
    end
  end
})

-- Recommended plugins for JavaScript/TypeScript development (add these to your Lazy setup)
-- Comment out any you don't want to use
local js_plugins = {
  -- 'pmizio/typescript-tools.nvim',
  -- 'davidosomething/format-ts-errors.nvim',
  -- 'mfussenegger/nvim-dap',
  -- 'rcarriga/nvim-dap-ui',
  -- 'mxsdev/nvim-dap-vscode-js',
}

-- Display runtime environment in statusline
local function js_env()
  if vim.fn.filereadable("package.json") == 1 then
    local runtime = ""
    
    if project_type == "react" then
      runtime = "React"
    elseif project_type == "vue" then
      runtime = "Vue"
    elseif project_type == "angular" then
      runtime = "Angular"
    elseif project_type == "svelte" then
      runtime = "Svelte"
    elseif project_type == "next" then
      runtime = "Next.js"
    elseif project_type == "nuxt" then
      runtime = "Nuxt.js"
    elseif project_type == "node" then
      runtime = "Node.js"
    else
      runtime = "JS"
    end
    
    return "[" .. runtime .. "]"
  end
  return ""
end

-- Ensure this is available to lualine or other statusline plugins
_G.js_env = js_env