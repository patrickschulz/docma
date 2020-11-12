return [[
Search and display documents (documents, documentation etc.)
If only the key is given (no options), the author, the title and the keywords are searched.
Passing an option turns off all other (non-passed) options, so using --author --title --keyword is the same as using no option.

Options summary:

Main search functions:
    <keys...> (default "")        The key for searching
    -m,--match (default "and")    mode for matching 
                                      possible values:
                                      "and": match ALL keys (default)
                                      "or" : match at least ONE key)
    -a,--author                   interpret the key as author
    -t,--title                    interpret the key as title
    -k,--keyword                  interpret the key as keyword
    --tag                         interpret the key as tag
    -T,--type                     Only show documents of certain type (currently not implemented)
    -g,--grep (default "")        don't search metadata, but use pdfgrep in order to search the documents. 
                                  Warning: this takes a long time, so make sure to narrow down your list of 
                                  documents to be searched (the regular search is performed first)
    -H,--hightlight               highlight the matched part of the document (author, keyword, title) (currently not implemented)
    -u,--unread                   Only show unread documents
    -r,--rating (default 0)       Only show documents with rating x or higher
    --unrated                     Only show unrated documents (currently not implemented)
    -D,--date (default '> 0')     Only show documents fulfilling the date specification
Output functions:
    -b,--bibtex-entry             print the bibtex entry for this document. If no entry is present, 
                                  a rudimentary entry will be assembled from available data
History functions:
    -S,--last-search              Redo last search and document selection
    -L,--last-N (default 1)       Open N-th last document                   (currently not implemented)
    --clear-last-search           Removes the last search from the history  (currently not implemented)
    --show-last-documents         Show last documents
    --show-last-search            Show last search (last keys)
Modification functions:
    --rate (default 3)            Rate the document                          (currently not implemented)
    --delete                      Remove the paper from index and it's file  (currently not implemented)
Generation functions:
    -G,--generate                 generate an entry (interactive)
    -B,--bibtex                   generate an entry from an bibtex file (two arguments needed: 1. bibtex file, 2. pdf filename)
Auxiliary functions:
    --copy                        copy the document to the current directory
    --path                        show the full path of the document
    --stdout                      all actions writing to files print to standard output instead (currently not implemented)
Cosmetic functions:
    --color (default 'on')        enable/disable color: 'on' or 'off'
    --sort (default 'author')     choose sorting of documents displayed in selection
    -M,--menu                     Display a curses menu for document selection (currently not implemented)
Debugging functions:
    --nowrite                     Disable all destructive actions (such as update data.lua)
    --check                       Check all data files, also check if there are orphaned pdfs 
    -v,--verbose                  report all loaded datafiles
    --debug                       enable debug prints
    --show-config                 show the loaded config, then exit
    -e,--entry                    show the database entry for the requested document
    --local                       Only read the data file found in the current directory
    --list-all                    List all loaded documents
]]
