# term-utils.nvim

Collection of utilities for neovim terminal mode. They solve a number of unrelated use-cases for me:

- Have multiple terminals open and quickly find the right one
- Quickly swap between an 'active' terminal and other windows
- Automatically run a terminal command on save, e.g. reload a repl or re-run a
  test/script


#### Installation

with plug.vim:

    Plug 'Tarmean/term-utils.nvim'

#### Managing multiple terminals

The core is the 'Term' command, syntax

    Term label command

The label autocompletes. If there is a terminal with some label, switch to it or open it. Otherwise open a new terminal using 'command' as initial command. Close a terminal by deleting the buffer.

#### Quick swapping:

The previously used label is remembered, and you should map a key to toggle between the current window and this terminal. This switches to a window with the active terminal, even if it is in another tab, or opens a new window if the terminal is currently closed. When used in the active terminal, it switches back to the previous windows

For these mappings you should use a key that you never use, even in terminal mode. If your keyboard has umlauts they would be good candidates. Example configuration:

    nnoremap ~ :call term_utils#term_toggle('insert', term_utils#guess_term_tag())<cr>
    tnoremap ~ <C-\><C-n>:call term_utils#goto_old_win(v:false)<cr>
    noremap ` :call term_utils#term_toggle('normal', term_utils#guess_term_tag( ))<cr>
    tnoremap ` <C-\><C-n>

    cnoremap term Term


A 'normal' mapping enters the terminal in normal mode instead of insert mode to enable easy copy-pasting.

#### Automatic commands on save

The `:Autoreload python program.py` executes `python program.py` in the `repl` terminal when the current buffer is saved. 

`Autoreload!` disables autoreloading again.

#### Misc

`:Term!` works like term, but cd's to the directory of the current file.

`:RTerm` works like `:Term`, but uses fugitive to run in the current git project root. Example:

    command! PHPShell RTerm php php -a -d auto_prepend_file=bootstrap_application.php

would open a php shell, labeled 'php', and load some initialization file. The terminal is cd'd to the project root so the paths make sense.


`:TermTag tag` sets a new tag for an existing terminal. Use `:TermTag! tag` to *add* this tag if you want multiple tags for the same terminal.


