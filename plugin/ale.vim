" Author: w0rp <devw0rp@gmail.com>
" Description: Main entry point for the plugin: sets up prefs and autocommands
"   Preferences can be set in vimrc files and so on to configure ale

" Sanity Checks

if exists('g:loaded_ale')
    finish
endif

let g:loaded_ale = 1

" A flag for detecting if the required features are set.
if has('nvim')
    let s:ale_has_required_features = has('timers')
else
    let s:ale_has_required_features = has('timers') && has('job') && has('channel')
endif

if !s:ale_has_required_features
    echoerr 'ALE requires NeoVim >= 0.1.5 or Vim 8 with +timers +job +channel'
    echoerr 'Please update your editor appropriately.'
    finish
endif

" This global variable is used internally by ALE for tracking information for
" each buffer which linters are being run against.
let g:ale_buffer_info = {}

" User Configuration

" This option prevents ALE autocmd commands from being run for particular
" filetypes which can cause issues.
let g:ale_filetype_blacklist = ['nerdtree', 'unite']

" This function lets you define autocmd commands which blacklist particular
" filetypes.
function! ALEAutoCMD(events, function_call)
    execute 'autocmd '
    \   . a:events
    \   ' * if index(g:ale_filetype_blacklist, &filetype) < 0 | call '
    \   . a:function_call
endfunction

" This Dictionary configures which linters are enabled for which languages.
let g:ale_linters = get(g:, 'ale_linters', {})

" This Dictionary allows users to set up filetype aliases for new filetypes.
let g:ale_linter_aliases = get(g:, 'ale_linter_aliases', {})

" This flag can be set with a number of milliseconds for delaying the
" execution of a linter when text is changed. The timeout will be set and
" cleared each time text is changed, so repeated edits won't trigger the
" jobs for linting until enough time has passed after editing is done.
let g:ale_lint_delay = get(g:, 'ale_lint_delay', 200)

" This flag can be set to 0 to disable linting when text is changed.
let g:ale_lint_on_text_changed = get(g:, 'ale_lint_on_text_changed', 1)
if g:ale_lint_on_text_changed
    augroup ALERunOnTextChangedGroup
        autocmd!
        call ALEAutoCMD('TextChanged,TextChangedI', 'ale#Queue(g:ale_lint_delay)')
    augroup END
endif

" This flag can be set to 0 to disable linting when the buffer is entered.
let g:ale_lint_on_enter = get(g:, 'ale_lint_on_enter', 1)
if g:ale_lint_on_enter
    augroup ALERunOnEnterGroup
        autocmd!
        call ALEAutoCMD('BufEnter,BufRead', 'ale#Queue(100)')
    augroup END
endif

" This flag can be set to 1 to enable linting when a buffer is written.
let g:ale_lint_on_save = get(g:, 'ale_lint_on_save', 0)
if g:ale_lint_on_save
    augroup ALERunOnSaveGroup
        autocmd!
        call ALEAutoCMD('BufWrite', 'ale#Queue(0)')
    augroup END
endif

" This flag can be set to 0 to disable setting the loclist.
let g:ale_set_loclist = get(g:, 'ale_set_loclist', 1)

" This flag can be set to 0 to disable setting signs.
" This is enabled by default only if the 'signs' feature exists.
let g:ale_set_signs = get(g:, 'ale_set_signs', has('signs'))

" These variables dicatate what sign is used to indicate errors and warnings.
let g:ale_sign_error = get(g:, 'ale_sign_error', '>>')
let g:ale_sign_warning = get(g:, 'ale_sign_warning', '--')

" This variable sets an offset which can be set for sign IDs.
" This ID can be changed depending on what IDs are set for other plugins.
" The dummy sign will use the ID exactly equal to the offset.
let g:ale_sign_offset = get(g:, 'ale_sign_offset', 1000000)

" This flag can be set to 1 to keep sign gutter always open
let g:ale_sign_column_always = get(g:, 'ale_sign_column_always', 0)

" String format for the echoed message
" A %s is mandatory
" It can contain 2 handlers: %linter%, %severity%
let g:ale_echo_msg_format = get(g:, 'ale_echo_msg_format', '%s')

" Strings used for severity in the echoed message
let g:ale_echo_msg_error_str = get(g:, 'ale_echo_msg_error_str', 'Error')
let g:ale_echo_msg_warning_str = get(g:, 'ale_echo_msg_warning_str', 'Warning')

" This flag can be set to 0 to disable echoing when the cursor moves.
let g:ale_echo_cursor = get(g:, 'ale_echo_cursor', 1)
if g:ale_echo_cursor
    augroup ALECursorGroup
        autocmd!
        call ALEAutoCMD('CursorMoved,CursorHold', 'ale#cursor#EchoCursorWarningWithDelay()')
    augroup END
endif

" String format for statusline
" Its a list where:
" * The 1st element is for errors
" * The 2nd element is for warnings
" * The 3rd element is when there are no errors
let g:ale_statusline_format = get(g:, 'ale_statusline_format',
\   ['%d error(s)', '%d warning(s)', 'OK']
\)

" This flag can be set to 0 to disable warnings for trailing whitespace
let g:ale_warn_about_trailing_whitespace =
\   get(g:, 'ale_warn_about_trailing_whitespace', 1)

" Define commands for moving through warnings and errors.
command! ALEPrevious :call ale#loclist_jumping#Jump('before', 0)
command! ALEPreviousWrap :call ale#loclist_jumping#Jump('before', 1)
command! ALENext :call ale#loclist_jumping#Jump('after', 0)
command! ALENextWrap :call ale#loclist_jumping#Jump('after', 1)

" <Plug> mappings for commands
nnoremap <silent> <Plug>(ale_previous) :ALEPrevious<Return>
nnoremap <silent> <Plug>(ale_previous_wrap) :ALEPreviousWrap<Return>
nnoremap <silent> <Plug>(ale_next) :ALENext<Return>
nnoremap <silent> <Plug>(ale_next_wrap) :ALENextWrap<Return>

" Housekeeping

augroup ALECleanupGroup
    autocmd!
    " Clean up buffers automatically when they are unloaded.
    call ALEAutoCMD('BufUnload', "ale#cleanup#Buffer(expand('<abuf>'))")
augroup END

" Backwards Compatibility

function! ALELint(delay)
    call ale#Queue(a:delay)
endfunction

function! ALEGetStatusLine()
    return ale#statusline#Status()
endfunction
