FROM frolvlad/alpine-glibc

MAINTAINER Yuu YOSHIMURA <yyu [at] mental.poker>

ENV REPOSITORY http://ftp.jaist.ac.jp/pub/CTAN/systems/texlive/tlnet

ENV PATH /usr/local/texlive/bin/x86_64-linux:$PATH

RUN apk --no-cache add perl wget xz tar fontconfig-dev make && \
    mkdir -p /tmp/install-tl-unx && \
    wget -qO- "$REPOSITORY/install-tl-unx.tar.gz" | \
      tar -xz -C /tmp/install-tl-unx --strip-components=1 && \
    printf "%s\n" \
      "selected_scheme scheme-basic" \
      "TEXDIR /usr/local/texlive" \
      "TEXMFSYSCONFIG /usr/local/texlive/texmf-config" \
      "TEXMFSYSVAR /usr/local/texlive/texmf-var" \
      "TEXMFHOME ~/texlive/texmf" \
      "TEXMFVAR ~/texlive/texmf-var" \
      "TEXMFCONFIG  ~/texlive/texmf-config" \
      "TEXMFLOCAL ~/texlive/texmf-local" \
      "option_doc 0" \
      "option_src 0" \
      > /tmp/install-tl-unx/texlive.profile && \
    /tmp/install-tl-unx/install-tl \
      -profile /tmp/install-tl-unx/texlive.profile \
      -repository http://ftp.jaist.ac.jp/pub/CTAN/systems/texlive/tlnet && \
    tlmgr \
      -repository $REPOSITORY \
      install \
        collection-luatex collection-fontsrecommended collection-langjapanese \
        latexmk enumitem menukeys xstring adjustbox collectbox relsize \
        catoptions cprotect bigfoot libertine && \
    apk --no-cache del xz tar fontconfig-dev && \
      rm -rf /tmp/install-tl-unx

RUN apk --no-cache add bash

RUN mkdir /workdir

WORKDIR /workdir

VOLUME ["/workdir"]

CMD ["bash"]
