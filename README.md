# Document Manager
This is a simple command-line document manager written in lua. It searches through a database for the authors, the title and the keywords of a document. Mutiple keywords can be combined by *and* (all
keywords must match) or *or* (only one keyword must match). A *not* functionality is currently not implemented. Furthermore, the user can restrict the search to only the author, the title or the
keywords.

# Syntax
Use *doc* without arguments to see a summary of all options:

    Options summary:
        <keys...> (string)      The key for searching
        --and (default true)    match ALL keys
        --or                    match at least ONE key
        -a,--author             interpret the key as author
        -t,--title              interpret the key as title
        -k,--keyword            interpret the key as keyword
        -o,--open               open the found document (if there is only one)

# Database Format
The database (`database.lua`) is a regular lua table with the following format:

    return {
        { 
            title = "Title of the document", 
            authors = { "First Author", "Second Author" }, 
            keywords = { "first keyword", "second keyword" },
            path = "/path/to/document"
        },
        { 
            title = "Title of the document", 
            authors = { "First Author", "Second Author" }, 
            keywords = { "first keyword", "second keyword" },
            path = "relativepathname"
        }
    }

# Roadmap
- I want to highlight the matched keyword in the paper output
