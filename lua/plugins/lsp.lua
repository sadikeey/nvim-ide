return {
	"neovim/nvim-lspconfig",
	lazy = true,
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"jose-elias-alvarez/typescript.nvim",
	},
	config = function()
		-- Using protected call
		local lsp_ok, lspconfig = pcall(require, "lspconfig")
		if not lsp_ok then
			return
		end
		local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
		if not cmp_nvim_lsp_ok then
			return
		end
		local typescript_ok, typescript = pcall(require, "typescript")
		if not typescript_ok then
			return
		end
		require("lspconfig.ui.windows").default_options.border = "rounded"

		-- Setting up icons for diagnostics
		local signs = {
			{ name = "DiagnosticSignError", text = "" },
			{ name = "DiagnosticSignWarn", text = "" },
			{ name = "DiagnosticSignHint", text = "" },
			{ name = "DiagnosticSignInfo", text = "" },
		}
		for _, sign in ipairs(signs) do
			vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
		end

		vim.diagnostic.config({
			virtual_text = true,
			signs = {
				active = signs,
			},
			update_in_insert = true,
			underline = true,
			severity_sort = true,
			float = {
				focusable = false,
				style = "minimal",
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
				suffix = "",
			},
		})
		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
			border = "rounded",
		})

		vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
			border = "rounded",
		})

		-- Setting up capabilities
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Setting up on_attach
		local on_attach = function(client, bufnr)
			local opts = { silent = true, buffer = bufnr }

			-- Setting keymaps for lsp
			vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
			vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
			vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)
			vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts)
			vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
			vim.keymap.set("n", "dl", vim.diagnostic.open_float, opts)
			vim.keymap.set("n", "d]", vim.diagnostic.goto_next, opts)
			vim.keymap.set("n", "d[", vim.diagnostic.goto_prev, opts)
			vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, opts)
			vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, opts)
			vim.keymap.set("n", "<leader>ls", vim.lsp.buf.signature_help, opts)
			vim.keymap.set("n", "<leader>lq", vim.diagnostic.setloclist, opts)
			vim.keymap.set("n", "<leader>li", vim.cmd.LspInfo, opts)

			-- Typescript specific settings
			if client.name == "tsserver" then
				client.server_capabilities.documentFormattingProvider = false
				vim.keymap.set("n", "<leader>lR", vim.cmd.TypescriptRenameFile, opts)
			end
		end

		-- Setting up servers
		local servers = { "html", "cssls", "eslint", "jsonls", "bashls", "tailwindcss" }
		for _, server in ipairs(servers) do
			if lspconfig[server] then
				lspconfig[server].setup({ on_attach = on_attach, capabilities = capabilities })
			end
		end

		-- Setting up lua server
		lspconfig.lua_ls.setup({
			on_attach = on_attach,
			capabilities = capabilities,
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = {
							[vim.fn.expand("$VIMRUNTIME/lua")] = true,
						},
					},
				},
			},
		})
		-- Setting up ts server
		typescript.setup({
			server = {
				on_attach = on_attach,
				capabilities = capabilities,
			},
		})
	end,
}
