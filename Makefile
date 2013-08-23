CHOOSER=c('boot', 'code')
BOOT_STYLE=NULL
CODE_STYLE=NULL

full_report.html: $(wildcard *.Rmd)

%.html: %.Rmd
	Rscript -e "\
    setwd('$(dir $<)');\
    require('knitrBootstrap');\
    knit_bootstrap('$(notdir $<)',\
      chooser=$(CHOOSER),\
      boot_style=$(BOOT_STYLE),\
      code_style=$(CODE_STYLE)\
    )"

make clean:
	GLOBIGNORE=README.md && rm -f *.md *.html
