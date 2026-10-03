# LESSONS

1. **The highlight is MA Reader web's** (`~/.maread-web/static/index.html`, `clockSample`, `highlightWordAt`):
   a predicted clock on wall time, eased halfway to each real position, snapped when 0.35 s off; the lit word
   is the last started at clock + 50 ms; the last word lets go 0.12 s after its end. Copied, not reinvented.
2. **Character offsets vs bytes**: the server's word offsets count characters; `hs.styledtext` counts bytes like
   `string.sub`. `utf8.offset` converts; without it a "−" or an accented letter shifts every later highlight.
