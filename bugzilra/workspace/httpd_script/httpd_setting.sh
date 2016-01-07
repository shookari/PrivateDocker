#!/bin/bash

export PERL_MM_USE_DEFAULT=1
export PERL_EXTUTILS_AUTOINSTALL="--defaultdeps"

perl -MCPAN -e 'install "Date::Parse"'
perl -MCPAN -e 'install "Template"'
perl -MCPAN -e 'install "AppConfig"'
perl -MCPAN -e 'install "CGI::Carp"'
perl -MCPAN -e 'install "URI::Escape"'
perl -MCPAN -e 'install "DBI"'

tar -xvzf ./DBD-mysql-4.033.tar.gz
cd DBD-mysql-4.033;
perl Makefile.PL
make 
make install
