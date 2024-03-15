FROM arm32v7/alpine:3.19.1 as buildapk
RUN apk add perl wget tar gzip
RUN apk add make gcc binutils grep chrpath
RUN apk add perl-par-packer
RUN apk add perl-cpan-distnameinfo
RUN apk add\
	perl-module-build\
	perl-class-accessor\
	perl-data-dump\
	perl-data-compare\
	perl-data-uniqid\
	perl-datetime-format-builder\
	perl-datetime-calendar-julian\
	perl-file-slurper\
	perl-ipc-run3\
	perl-list-allutils\
	perl-list-moreutils\
	perl-list-moreutils-xs\
	perl-mozilla-ca\
	perl-regexp-common\
	perl-log-log4perl\
	perl-unicode-collate\
	perl-unicode-linebreak\
	perl-encode-locale\
	perl-encode-eucjpascii\
	perl-encode-jis2k\
	perl-encode-hanextra\
	perl-perlio-utf8_strict\
	perl-xml-libxml\
	perl-xml-libxml-simple\
	perl-xml-libxslt\
	perl-xml-writer\
	perl-sort-key\
	perl-text-csv\
	perl-text-csv_xs\
	perl-lwp-protocol-https\
	perl-business-isbn\
	perl-business-issn\
	perl-business-ismn\
	perl-lingua-translit\
	perl-io-string\
	perl-parse-recdescent\
	perl-text-bibtex\
	perl-text-roman\
	perl-autovivification\
	perl-config-autoconf\
	perl-extutils-libbuilder\
	perl-file-which\
	perl-test-differences

FROM buildapk as buildperl
COPY MyConfig.pm /root/.cpan/CPAN/MyConfig.pm
COPY cpan /usr/local/bin/

FROM buildperl as buildbiber
ARG biberversion=2.19
WORKDIR /root
RUN wget https://github.com/plk/biber/archive/refs/tags/v${biberversion}.tar.gz -O- | tar xz && mv biber-${biberversion} biber
WORKDIR /root/biber
RUN perl Build.PL
RUN ./Build installdeps

FROM buildbiber as installbiber
WORKDIR /root/biber
RUN ./Build install

FROM installbiber as pack
# Prepare some libraries that have rpath..
# grep for RUNPATH in readelf -d ...
RUN chrpath -d\
	/usr/lib/perl5/core_perl/auto/Compress/Raw/Bzip2/Bzip2.so\
	/usr/lib/perl5/core_perl/auto/Compress/Raw/Zlib/Zlib.so\
	/usr/lib/perl5/vendor_perl/auto/XML/LibXSLT/LibXSLT.so\
	/usr/lib/perl5/vendor_perl/auto/Net/SSLeay/SSLeay.so\
	/usr/lib/perl5/vendor_perl/auto/XML/LibXML/LibXML.so
RUN PAR_VERBATIM=1 /usr/bin/pp \
	--module=deprecate \
	--module=Biber::Input::file::bibtex \
	--module=Biber::Input::file::biblatexml \
	--module=Biber::Output::dot \
	--module=Biber::Output::bbl \
	--module=Biber::Output::bblxml \
	--module=Biber::Output::bibtex \
	--module=Biber::Output::biblatexml \
	--module=Pod::Simple::TranscodeSmart \
	--module=Pod::Simple::TranscodeDumb \
	--module=List::MoreUtils::XS \
	--module=List::MoreUtils::PP \
	--module=HTTP::Status \
	--module=HTTP::Date \
	--module=Encode:: \
	--module=File::Find::Rule \
	--module=IO::Socket::SSL \
	--module=IO::String \
	--module=PerlIO::utf8_strict \
	--module=Text::CSV_XS \
	--module=DateTime \
	--link=xml2.so.2 \
	--link=liblzma.so.5 \
	--link=btparse.so \
	--addfile="/root/biber/data/biber-tool.conf;lib/Biber/biber-tool.conf" \
	--addfile="/root/biber/data/schemata/config.rnc;lib/Biber/config.rnc" \
	--addfile="/root/biber/data/schemata/config.rng;lib/Biber/config.rng"\
	--addfile="/root/biber/data/schemata/bcf.rnc;lib/Biber/bcf.rnc" \
	--addfile="/root/biber/data/schemata/bcf.rng;lib/Biber/bcf.rng" \
	--addfile="/root/biber/lib/Biber/LaTeX/recode_data.xml;lib/Biber/LaTeX/recode_data.xml" \
	--addfile="/root/biber/data/bcf.xsl;lib/Biber/bcf.xsl" \
	--addfile="/usr/share/perl5/vendor_perl/Business/ISBN/RangeMessage.xml" \
	--addfile="/usr/share/perl5/vendor_perl/Mozilla/CA/cacert.pem" \
	--addfile="/usr/share/perl5/core_perl/PerlIO" \
	--addfile="/usr/share/perl5/core_perl/Unicode/Collate/Locale;lib/Unicode/Collate/Locale" \
	--addfile="/usr/share/perl5/core_perl/Unicode/Collate/CJK;lib/Unicode/Collate/CJK" \
	--addfile="/usr/share/perl5/core_perl/Unicode/Collate/allkeys.txt;lib/Unicode/Collate/allkeys.txt" \
	--addfile="/usr/share/perl5/core_perl/Unicode/Collate/keys.txt;lib/Unicode/Collate/keys.txt" \
	--cachedeps=scancache \
	--output=biber-linux_armv7_musl \
	/usr/local/bin/biber

#  --module=List::SomeUtils::XS \
#  --link=/lib/aarch64-linux-gnu/libz.so.1 \
#  --link=/lib/aarch64-linux-gnu/libgpg-error.so.0 \
#  --link=/lib/aarch64-linux-gnu/libcrypt.so.1 \
#  --link=/lib/aarch64-linux-gnu/libgcrypt.so.20 \
#  --link=/usr/local/lib/libbtparse.so \
#  --link=/usr/lib/aarch64-linux-gnu/libxslt.so \
#  --link=/usr/lib/aarch64-linux-gnu/libexslt.so \
#  --link=/usr/lib/aarch64-linux-gnu/libxml2.so \
#  --link=/usr/lib/aarch64-linux-gnu/libicui18n.so.63 \
#  --link=/usr/lib/aarch64-linux-gnu/libicuuc.so \
#  --link=/usr/lib/aarch64-linux-gnu/libicudata.so \
#  --link=/usr/lib/aarch64-linux-gnu/liblzma.so \
#  --link=/usr/lib/aarch64-linux-gnu/libssl.so \

FROM arm32v7/alpine:3.19.1 as pretest
COPY --from=pack /root/biber/biber-linux_armv7_musl .

FROM pretest as test
RUN ./biber-linux_armv7_musl --help
CMD cp /biber-linux_armv7_musl /lib/ld-musl-armhf.so.1 /lib/libc.musl-armv7.so.1 /root/ext
