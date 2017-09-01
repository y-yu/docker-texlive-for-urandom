FROM alpine:3.5

MAINTAINER Yuu YOSHIMURA <yyu [at] mental.poker>

# If you bulid this in Japanese, you should use the following argument:
ARG REPOSITORY=http://ftp.jaist.ac.jp/pub/CTAN/systems/texlive/tlnet
# ARG REPOSITORY=http://ctan.sharelatex.com/tex-archive/systems/texlive/tlnet

ENV PATH=/usr/local/texlive/bin/x86_64-linux:$PATH

ENV LANG=ja_JP.UTF-8

# Install glibc and Set ja_JP.UTF-8 locale as default
# This is copy from frolvlad/alpine-glibc
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.25-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget \
        "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
        -O "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 ja_JP.UTF-8 || true && \
    echo "export LANG=ja_JP.UTF-8" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

RUN apk --no-cache add bash wget perl fontconfig-dev make python py-pip

# Set Timezone to Tokyo
RUN apk --no-cache add tzdata && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo 'Asia/Tokyo' > /etc/timezone && \
    apk --no-cache del tzdata

# Install Pandoc and Pandocfilters
# This is copy from conoria/alpine-pandoc
RUN wget --no-check-certificate -O /etc/apk/keys/conor.rsa.pub \
      "https://raw.githubusercontent.com/ConorIA/dockerfiles/master/alpine-pandoc/conor@conr.ca-584aeee5.rsa.pub" && \
    echo https://conoria.gitlab.io/alpine-pandoc/ >> /etc/apk/repositories && \
    echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --no-cache cmark@testing pandoc && \
    rm /etc/apk/keys/conor.rsa.pub && \
    pip install pandocfilters

# Install TeXLive and Fonts
RUN apk --no-cache add xz tar && \
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
        collection-latexrecommended latexmk enumitem menukeys \
        type1cm xkeyval everyhook svn-prov etoolbox \
        libertine newtx quotchap datetime2 tracklang \
        mathtools pdfpages subfiles cm-unicode boondox \
        xstring pgf adjustbox collectbox relsize catoptions && \
    mkdir -p /tmp/source-code-pro && \
    wget -qO- --no-check-certificate \
      https://github.com/adobe-fonts/source-code-pro/archive/2.030R-ro/1.050R-it.tar.gz | \
        tar -xz -C /tmp/source-code-pro && \
    mkdir -p /root/.fonts && \
    cp /tmp/source-code-pro/source-code-pro-2.030R-ro-1.050R-it/OTF/*.otf /root/.fonts/ && \
    apk --no-cache del xz tar && \
    rm -rf /tmp/install-tl-unx /tmp/source-code-pro

RUN mkdir /workdir

WORKDIR /workdir

VOLUME ["/workdir"]

CMD ["bash"]
