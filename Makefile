.DEFAULT_GOAL := pdf


define INFORMATION
Makefile for automated typography using pandoc.

Version 1.8

Usage:
make prepare                    first time use, setting the directories
make prepare-latex              create a minimal latex install
make dependencies               tries to fetch all included packages in the project and install them
make html                       generate a web version
make pdf                        generate a PDF file
make docx                       generate a Docx file
make tex                        generate a Latex file
make beamer                     generate a beamer presentation
make all                        generate all files
make fetch THEME=<github addrs> fetch the theme for a template online
make update                     update the makefile to last version
make update-testing-branch      update to latest testing version
make                            will fallback to PDF

It implies some directories in the filesystem: source, output and style
It also implies that the bibliography file will be defined via the yaml
Depends on pandoc-citeproc and pandoc-crossref
endef

export INFORMATION

SHELL = /bin/bash

MD = $(wildcard source/*.md)
PDF = output/$(notdir $(CURDIR)).pdf
TEX = output/$(notdir $(CURDIR)).tex
DOCX = output/$(notdir $(CURDIR)).docx
HTML5 = output/$(notdir $(CURDIR)).html
EPUB = output/$(notdir $(CURDIR)).epub
BEAMER = output/$(notdir $(CURDIR))-presentation.pdf
PACKAGES = s~^[^%]*\\usepackage[^{]*{\([^}]*\)}.*$$~\1~p


FILFILES = $(wildcard style/*.py)
FILFILES += $(wildcard style/*.lua)
FILTERS := $(foreach FILFILES, $(FILFILES), --filter $(FILFILES))
TEXFLAGS = -F pandoc-crossref -F pandoc-citeproc --pdf-engine=xelatex

ifneq ("$(wildcard style/Makefile)","")
	include style/Makefile
endif
ifneq ("$(wildcard style/template.tex)","")
	TEXTEMPLATE := "--template=style/template.tex"
endif
ifneq ("$(wildcard style/reference.docx)","")
	DOCXTEMPLATE := "--reference-docx=style/reference.docx"
endif
ifneq ("$(wildcard style/template.html)","")
	HTMLTEMPLATE := "--template=style/template.html"
endif
ifneq ("$(wildcard style/template.epub)","")
	EPUBTEMPLATE := "--template=style/template.epub"
endif
ifneq ("$(wildcard style/preamble.tex)","")
	TEXPREAMBLE := "--include-in-header=style/preamble.tex"
endif
ifneq ("$(wildcard style/epub.css)","")
	EPUBSTYLE := "--epub-stylesheet=style/epub.css"
endif
ifneq ("$(wildcard style/style.css)","")
	CSS := "--include-in-header=style/style.css"
endif
ifneq ("$(wildcard style/citation.csl)","")
	CSL := "--csl=style/citation.csl"
endif

help:
	@echo "$$INFORMATION"

all : tex docx html5 epub pdf

pdf: DYNAMICFLAGS = $(TEXTEMPLATE) $(TEXPREAMBLE) $(CSL)
pdf: $(PDF)
$(PDF): $(MD)
	pandoc -o $@ source/*.md $(TEXFLAGS) $(DYNAMICFLAGS) $(FILTERS) 2>output/pdf.log

tex: DYNAMICFLAGS = $(TEXTEMPLATE) $(TEXPREAMBLE) $(CSL)
tex: $(TEX)
$(TEX): $(MD)
	pandoc -o $@ source/*.md $(TEXFLAGS) $(DYNAMICFLAGS) 2>output/tex.log

docx: DYNAMICFLAGS = $(DOCXTEMPLATE) $(CSL)
docx: $(DOCX)
$(DOCX): $(MD)
	pandoc -o $@ source/*.md $(TEXFLAGS) $(DYNAMICFLAGS) --toc 2>output/docx.log

html5: DYNAMICFLAGS = $(HTMLTEMPLATE) $(CSS) $(CSL)
html5: $(HTML5)
$(HTML5): $(MD)
	pandoc -o $@ source/*.md $(TEXFLAGS) $(DYNAMICFLAGS) --toc -t html5 2>output/html5.log

epub: DYNAMICFLAGS = $(EPUBSTYLE) $(EPUBTEMPLATE) $(CSL)
epub: $(EPUB)
$(EPUB): $(MD)
	pandoc -o $@ source/*.md $(TEXFLAGS) $(DYNAMICFLAGS) --toc 2>output/epub.log

tex: DYNAMICFLAGS = $(TEXTEMPLATE) $(TEXPREAMBLE) $(CSL)
beamer: $(BEAMER)
$(BEAMER): $(MD)
	pandoc -o $@ source/*.md $(TEXFLAGS) $(DYNAMICFLAGS) -t beamer 2>output/beamer.log

prepare:
	command -v xetex >/dev/null 2>&1 || { echo "Latex is not installed.  Please run make prepare-latex for a minimal installation." >&2; exit 1; }
	command -v pandoc >/dev/null 2>&1 || { echo "I require pandoc but it's not installed.  Aborting." >&2; exit 1; }
	command -v pandoc-crossref >/dev/null 2>&1 || { echo "I require pandoc-crossref but it's not installed.  Aborting." >&2; exit 1; }
	command -v pandoc-citeproc >/dev/null 2>&1 || { echo "I require pandoc-citeproc but it's not installed.  Aborting." >&2; exit 1; }
	command -v svn >/dev/null 2>&1 || { echo "I require svn but it's not installed.  Aborting." >&2; exit 1; }
	mkdir "output"
	mkdir "source"
	mkdir "style"
	touch source/00-metadata.md

fetch:
	command -v svn >/dev/null 2>&1 || { echo "I require svn but it's not installed.  Aborting." >&2; exit 1; }
	@echo "Trying to fetch the style directory from this github repo"
	svn export $(THEME).git/trunk/style

prepare-latex:
	@echo "This will install a latex minimal installation, but tlmgr can be used to fill in the packages."
	@echo "To automatically perform dependency installations run make dependencies in the project directory."
	@echo "Note that installing a latex distribution takes some trial and error, "
	@echo "the approach I used here is the one that creates the smallest distribution."
	@echo "Ubuntu's latex distribution can be up to 2.8GB, whereas with this method it only takes around 1GB."
	wget \
	--continue \
	--directory-prefix /tmp \
	http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz

	tar \
	--extract \
	--gunzip \
	--directory /tmp \
	--file /tmp/install-tl-unx.tar.gz

	pkexec /tmp/install-tl-*/install-tl \
	-repository http://mirror.ctan.org/systems/texlive/tlnet \
	-no-gui \
	-scheme scheme-minimal
	@echo "It's done. Use <tlmgr install PACKAGENAME> to install the packages you need."

dependencies:
	pkexec tlmgr install $$(cat source/*.md | sed -n '$(PACKAGES)' | paste -sd ' ' -) $$(cat style/*.tex | sed -n '$(PACKAGES)' | paste -sd ' ' -)

update:
	wget http://tiny.cc/mighty_make -O Makefile

update-testing-branch:
	wget http://tiny.cc/mighty_test -O Makefile

clean:
	rm -f output/*.{md,html,tex,docx,pdf,epub}

.PHONY: help prepare update beamer clean
