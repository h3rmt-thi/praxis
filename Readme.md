Enter Env:
```bash
nix develop --command $SHELL

# start VScode in shell so it has access to latexmk, etc.
code .
```

Build Latex:
```bash
beamer-build
document-build
```

Format Latex:
```bash
beamer-format
document-format
```

Present:
```bash
beamer-present
```

### Beamer notes
This uses pdfpc to present. 
pdfpc allows notes in md format (legacy), that get converted into a json format on first launch.
The md notes are generated with a custom plugin (pdfpcnotes). 
This is a modification of the original notes plugin that allows different notes for pages split by `\pause`

To convert the notes into the new format pdfpc is started and then stoped via killactive (pkill doesnt work beause then the new config wont be saved).
It is then called again beause when opening with the old config file the `--note-format=markdown` doesn't work

### VSCode

install `James-Yu.latex-workshop` (LaTeX Workshop).

It is recemended to set
```json
"latex-workshop.latex.outDir": "%DIR%/out",
"latex-workshop.formatting.latex": "latexindent"
```