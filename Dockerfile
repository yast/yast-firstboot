FROM yastdevel/ruby:sle15-sp1
RUN zypper --gpg-auto-import-keys --non-interactive in --no-recommends \
  docbook-xsl-stylesheets yast2-configuration-management
COPY . /usr/src/app

