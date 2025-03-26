local dap = require('dap')
local dapui = require('dapui')

-- UI Configuration
dapui.setup({
  icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
  mappings = {
    -- Use a table to apply multiple mappings
    expand = { "<CR>", "<2-LeftMouse>" },
    open = "o",
    remove = "d",
    edit = "e",
    repl = "r",
    toggle = "t",
  },
  layouts = {
    {
      elements = {
        -- Elements can be strings or table with id and size keys.
        { id = "scopes", size = 0.25 },
        { id = "breakpoints", size = 0.25 },
        { id = "stacks", size = 0.25 },
        { id = "watches", size = 0.25 },
      },
      size = 40, -- 40 columns
      position = "left",
    },
    {
      elements = {
        "repl",
        "console",
      },
      size = 0.25, -- 25% of total lines
      position = "bottom",
    },
  },
  controls = {
    -- Requires Neovim nightly (or 0.8 when released)
    enabled = true,
    -- Display controls in this element
    element = "repl",
    icons = {
      pause = "",
      play = "",
      step_into = "",
      step_over = "",
      step_out = "",
      step_back = "",
      run_last = "",
      terminate = "",
    },
  },
  floating = {
    max_height = nil, -- These can be integers or a float between 0 and 1.
    max_width = nil, -- Floats will be treated as percentage of your screen.
    border = "single", -- Border style. Can be "single", "double" or "rounded"
    mappings = {
      close = { "q", "<Esc>" },
    },
  },
  windows = { indent = 1 },
  render = { 
    max_type_length = nil, -- Can be integer or nil.
    max_value_lines = 100, -- Can be integer or nil.
  }
})

-- Universal keymaps for debugging
vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
vim.keymap.set('n', '<leader>dB', function() dap.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, { desc = "Set conditional breakpoint" })
vim.keymap.set('n', '<leader>dc', dap.continue, { desc = "Continue/start debugging" })
vim.keymap.set('n', '<leader>do', dap.step_over, { desc = "Step over" })
vim.keymap.set('n', '<leader>di', dap.step_into, { desc = "Step into" })
vim.keymap.set('n', '<leader>dO', dap.step_out, { desc = "Step out" })
vim.keymap.set('n', '<leader>dr', dap.repl.open, { desc = "Open REPL" })
vim.keymap.set('n', '<leader>du', dapui.toggle, { desc = "Toggle debugger UI" })
vim.keymap.set('n', '<leader>dt', dap.terminate, { desc = "Terminate debug session" })

-- Automatically open/close UI
dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

-- Language-specific configurations
-- Python
dap.adapters.python = {
  type = 'executable',
  command = 'python',
  args = { '-m', 'debugpy.adapter' },
}

dap.configurations.python = {
  {
    type = 'python',
    request = 'launch',
    name = 'Launch file',
    program = "${file}",
    pythonPath = function()
      local venv = os.getenv('VIRTUAL_ENV')
      if venv then
        return venv .. '/bin/python'
      end
      return 'python'
    end,
  },
  {
    type = 'python',
    request = 'launch',
    name = 'Django',
    program = "${workspaceFolder}/manage.py",
    args = { 'runserver', '--noreload' },
    django = true,
  },
}

-- JavaScript/TypeScript
dap.adapters.node2 = {
  type = 'executable',
  command = 'node',
  args = { vim.fn.stdpath('data') .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js' },
}

dap.configurations.javascript = {
  {
    type = 'node2',
    request = 'launch',
    name = 'Launch file',
    program = "${file}",
    cwd = vim.fn.getcwd(),
    sourceMaps = true,
  },
  {
    type = 'node2',
    request = 'attach',
    name = 'Attach to process',
    processId = require('dap.utils').pick_process,
  },
}
dap.configurations.typescript = dap.configurations.javascript

-- Ruby
dap.adapters.ruby = {
  type = 'executable',
  command = 'bundle',
  args = {'exec', 'rdbg', '-n', '--open', '--port', '${port}'},
}

dap.configurations.ruby = {
  {
    type = 'ruby',
    request = 'launch',
    name = 'Rails',
    program = 'bundle',
    programArgs = {'exec', 'rails', 's'},
    useBundler = true,
  },
  {
    type = 'ruby',
    request = 'launch',
    name = 'RSpec current file',
    program = 'bundle',
    programArgs = {'exec', 'rspec', '${file}'},
    useBundler = true,
  },
}

-- Add to your plugins in init.lua
-- { 'mfussenegger/nvim-dap', dependencies = { 'rcarriga/nvim-dap-ui' } },
-- { 'mfussenegger/nvim-dap-python' },
-- { 'suketa/nvim-dap-ruby' },