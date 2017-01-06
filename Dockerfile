FROM yastdevel/ruby-tw
RUN zypper --gpg-auto-import-keys --non-interactive in --no-recommends \
  docbook-xsl-stylesheets
COPY . /tmp/sources

