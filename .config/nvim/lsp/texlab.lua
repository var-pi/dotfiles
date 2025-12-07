return {
    cmd = { 'texlab' },
    filetypes = { 'tex', 'plaintex', 'bib' },
    settings = {
        texlab = {
            build = {
                executable = 'latexmk',
                args = { '-pdf', '-interaction=nonstopmode', '%f' },
                onSave = true,
            },
        },
    },
}

