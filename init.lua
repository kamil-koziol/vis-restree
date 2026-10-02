-- vis-restree: run `restree` on the current file and show the result in a split view
-- https://github.com/kamil-koziol/restree
--
-- Usage:
--   :restree
--   :restree --jq
--   :restree --headers
--   :restree --jq --headers
--
--   --jq       parse the response using jq
--   --headers  show response headers
--
-- Add keybinds to your visrc if desired, for example:
--
--   vis:map(vis.modes.NORMAL, '\\rr', ':restree<Enter>')
--   vis:map(vis.modes.NORMAL, '\\rj', ':restree --jq<Enter>')
--   vis:map(vis.modes.NORMAL, '\\rh', ':restree --headers<Enter>')
--   vis:map(vis.modes.NORMAL, '\\ra', ':restree --jq --headers<Enter>')

local M = {
	bin = 'restree',
}

local function with_newline(s)
	if s ~= '' and s:sub(-1) ~= '\n' then
		return s .. '\n'
	end

	return s
end

-- Run restree for the file shown in `win` and open the result in a new vertical window.
local function run(win, args)
	local path = win.file and win.file.path

	if not path then
		vis:info('restree: the file has no path, save it first')
		return
	end

	-- restree writes the response body to stdout and headers/errors to stderr 
	local cmd = M.bin .. ' run -k -v "' .. path:gsub('"', '\\"') .. '"'

	local code, stdout, stderr = vis:pipe(nil, nil, cmd)

	if code == nil then
		vis:info('restree: could not run the command')
		return
	end

	stdout = stdout or ''
	stderr = stderr or ''

	local text = ''

	-- headers are written to stderr by restree.
	if args.headers and stderr ~= '' then
		text = with_newline(stderr) .. '\n'
	end

	-- Pretty-print only the response body.
	if args.jq and stdout ~= '' then
		local jq_code, formatted, jq_error = vis:pipe(
			stdout,
			'jq'
		)

		if jq_code == 0 then
			stdout = formatted or ''
		else
			-- Keep the original response body and report the jq error.
			text = text
				.. '--- ERROR (jq exit code '
				.. tostring(jq_code)
				.. ') ---\n'

			text = text .. with_newline(
				jq_error ~= '' and jq_error or 'jq failed to parse the response'
			)
		end
	end

	text = text .. stdout

	-- Show restree errors when the request itself failed.
	if code ~= 0 then
		if text ~= '' and text:sub(-1) ~= '\n' then
			text = text .. '\n'
		end

		text = text
			.. '--- ERROR (Exit Code '
			.. tostring(code)
			.. ') ---\n'

		-- Don't duplicate stderr when --headers already displayed it.
		if not args.headers then
			text = text .. with_newline(
				stderr ~= '' and stderr or 'Unknown Error'
			)
		end
	end

	-- Open the result in a new vertical split.
	vis:command('vnew')

	local out = vis.win

	out.file:insert(0, text)
	out.selection.pos = 0

	if args.jq then
		out:set_syntax('json')
	end

	-- The output buffer is modified because we inserted the result.
	-- Close it without prompting to save.
	out:map(vis.modes.NORMAL, 'q', function()
		vis:command('q!')
	end)
end

vis:command_register(
	'restree',
	function(argv, force, win, selection, range)
		local args = {
			jq = false,
			headers = false,
		}

		for _, arg in ipairs(argv) do
			if arg == '--jq' then
				args.jq = true
			elseif arg == '--headers' then
				args.headers = true
			else
				vis:info('restree: unknown option: ' .. arg)
				return false
			end
		end

		run(win, args)

		return true
	end,
	'run restree on the current file: restree [--jq] [--headers]'
)

return M
