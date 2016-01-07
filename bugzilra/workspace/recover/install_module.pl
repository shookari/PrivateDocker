#!/usr/bin/perl -w
# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# 이 파일의 내용물은 모질라 공개 라이센스 버전(Mozilla Public License
# Version - 이하 "라이센스") 1.1에 의해 보호됩니다. 라이센스에 준하지
# 않는 목적으로 이 파일을 사용하실 수는 없습니다. 라이센스에 대한 사본은
# http://www.mozilla.org/MPL/ 에서 구하실 수 있습니다.
#
# MPL 라이센스 하에 배포되는 소프트웨어는 "있는 그대로" 배포되는 것을
# 원칙으로 합니다. 한편 이 소프트웨어는 명시적으로든 묵시적으로든 간에 
# 어떠한 종류의 보증도 하지 않습니다. 권한과 제약사항들에 대한 보다 자세한
# 사항은 라이센스를 참고하시기 바랍니다.
#
# 원본 코드는 버그질라 버그 추적 시스템(Bugzilla Bug Tracking System)
# 입니다.
#
# 원본 코드의 초기 개발은 "넷스케이프 커뮤니케이션 코퍼레이션"에서 했음을 
# 밝혀 둡니다. 본 제품의 일부 중 Netscape 社에 의해 만들어진 것은 Copyright
# (C) 1998 Netscape Communications Corporation에 의해 보호되며, 모든 
# 권한은 Netscape에 있습니다.
#
# Contributor(s): Holger Schurig <holgerschurig@nikocity.de>
#                 Terry Weissman <terry@mozilla.org>
#                 Dan Mosedale <dmose@mozilla.org>
#                 Dave Miller <justdave@syndicomm.com>
#                 Zach Lipton  <zach@zachlipton.com>
#
#
# Direct any questions on this source code to
#
# Holger Schurig <holgerschurig@nikocity.de>
#
#
#
# Hey, what's this?
#
# 'checksetup.pl' is a script that is supposed to run during installation
# time and also after every upgrade.
#
# The goal of this script is to make the installation even more easy.
# It does so by doing things for you as well as testing for problems
# early.
#
# And you can re-run it whenever you want. Especially after Bugzilla
# gets updated you SHOULD rerun it. Because then it may update your
# SQL table definitions so that they are again in sync with the code.
#
# So, currently this module does:
#
#     - check for required perl modules
#     - set defaults for local configuration variables
#     - create and populate the data directory after installation
#     - set the proper rights for the *.cgi, *.html ... etc files
#     - check if the code can access MySQL
#     - creates the database 'bugs' if the database does not exist
#     - creates the tables inside the database if they don't exist
#     - automatically changes the table definitions of older BugZilla
#       installations
#     - populates the groups
#     - put the first user into all groups so that the system can
#       be administrated
#     - changes already existing SQL tables if you change your local
#       settings, e.g. when you add a new platform
#
# People that install this module locally are not supposed to modify
# this script. This is done by shifting the user settable stuff into
# a local configuration file 'localconfig'. When this file get's
# changed and 'checkconfig.pl' will be re-run, then the user changes
# will be reflected back into the database.
#
# Developers however have to modify this file at various places. To
# make this easier, I have added some special comments that one can
# search for.
#
#     To                                               Search for
#
#     add/delete local configuration variables         --LOCAL--
#     check for more prerequired modules               --MODULES--
#     change the defaults for local configuration vars --LOCAL--
#     update the assigned file permissions             --CHMOD--
#     add more MySQL-related checks                    --MYSQL--
#     change table definitions                         --TABLE--
#     add more groups                                  --GROUPS--
#     create initial administrator account             --ADMIN--
#
# Note: sometimes those special comments occur more then once. For
# example, --LOCAL-- is at least 3 times in this code!  --TABLE--
# also is used more than once. So search for every occurence!
#


###########################################################################
# Global definitions
###########################################################################

use diagnostics;
use strict;

# 12/17/00 justdave@syndicomm.com - removed declarations of the localconfig
# variables from this location.  We don't want these declared here.  They'll
# automatically get declared in the process of reading in localconfig, and
# this way we can look in the symbol table to see if they've been declared
# yet or not.


###########################################################################
# Check required module
###########################################################################

#
# Here we check for --MODULES--
#

print "\nPerl 모듈 체크...\n";
unless (eval "require 5.005") {
    die "죄송합니다만, 적어도 Perl 5.005 이상이 필요합니다.\n";
}

# vers_cmp is adapted from Sort::Versions 1.3 1996/07/11 13:37:00 kjahds,
# which is not included with Perl by default, hence the need to copy it here.
# Seems silly to require it when this is the only place we need it...
sub vers_cmp {
  if (@_ < 2) { die "vers_cmp 호출시 제공된 파라미터의 개수가 부족합니다." }
  if (@_ > 2) { die "vers_cmp 호출시 제공된 파라미터의 개수가 너무 많습니다." }
  my ($a, $b) = @_;
  my (@A) = ($a =~ /(\.|\d+|[^\.\d]+)/g);
  my (@B) = ($b =~ /(\.|\d+|[^\.\d]+)/g);
  my ($A,$B);
  while (@A and @B) {
    $A = shift @A;
    $B = shift @B;
    if ($A eq "." and $B eq ".") {
      next;
    } elsif ( $A eq "." ) {
      return -1;
    } elsif ( $B eq "." ) {
      return 1;
    } elsif ($A =~ /^\d+$/ and $B =~ /^\d+$/) {
      return $A <=> $B if $A <=> $B;
    } else {
      $A = uc $A;
      $B = uc $B;
      return $A cmp $B if $A cmp $B;
    }
  }
  @A <=> @B;
}

# This was originally clipped from the libnet Makefile.PL, adapted here to
# use the above vers_cmp routine for accurate version checking.
sub have_vers {
  my ($pkg, $wanted) = @_;
  my ($msg, $vnum, $vstr);
  no strict 'refs';
  printf("모듈 체크: %15s %-9s ", $pkg, !$wanted?'(any)':"(v$wanted)");

  eval { my $p; ($p = $pkg . ".pm") =~ s!::!/!g; require $p; };

  $vnum = ${"${pkg}::VERSION"} || ${"${pkg}::Version"} || 0;
  $vnum = -1 if $@;

  if ($vnum eq "-1") { # string compare just in case it's non-numeric
    $vstr = "찾지 못했습니다.";
  }
  elsif (vers_cmp($vnum,"0") > -1) {
    $vstr = "v$vnum 을/를 발견하였습니다.";
  }
  else {
    $vstr = "알 수 없는 버전을 발견하였습니다.";
  }

  my $vok = (vers_cmp($vnum,$wanted) > -1);
  print ((($vok) ? "ok: " : " "), "$vstr\n");
  return $vok;
}

# Check versions of dependencies.  0 for version = any version acceptible
my $modules = [ 
    { 
        name => 'AppConfig',  
        version => '1.52' 
    }, 
    { 
        name => 'CGI::Carp', 
        version => '0' 
    }, 
    {
        name => 'Data::Dumper', 
        version => '0' 
    }, 
    {        
        name => 'Date::Parse', 
        version => '0' 
    }, 
    { 
        name => 'DBI', 
        version => '1.13' 
    }, 
    { 
        name => 'DBD::mysql', 
        version => '1.2209' 
    }, 
    { 
        name => 'File::Spec', 
        version => '0.82' 
    }, 
    { 
        name => 'File::Temp',
        version => '0'
    },
    { 
        name => 'Template', 
        version => '2.07' 
    }, 
    { 
        name => 'Text::Wrap', 
        version => '2001.0131' 
    } 
];

my %missing = ();
foreach my $module (@{$modules}) {
    unless (have_vers($module->{name}, $module->{version})) { 
        $missing{$module->{name}} = $module->{version};
    }
}

# If CGI::Carp was loaded successfully for version checking, it changes the
# die and warn handlers, we don't want them changed, so we need to stash the
# original ones and set them back afterwards -- justdave@syndicomm.com
my $saved_die_handler = $::SIG{__DIE__};
my $saved_warn_handler = $::SIG{__WARN__};
unless (have_vers("CGI::Carp",0))    { $missing{'CGI::Carp'} = 0 }
$::SIG{__DIE__} = $saved_die_handler;
$::SIG{__WARN__} = $saved_warn_handler;

print "\n다음 Perl 모듈들은 옵셔널입니다:\n";
my $charts = 0;
$charts++ if have_vers("GD","1.19");
$charts++ if have_vers("Chart::Base","0.99");
my $xmlparser = have_vers("XML::Parser",0);

print "\n";
if ($charts != 2) {
    print "만약 그래프 형식의 버그 종속성 차트를 보시길 원하신다면, 추가적으로 libgb와\n",
    "Perl 모듈인 GD-1.19 및 Chart::Base-0.99b를 루트(root) 권한으로 설치하셔야 합니다.\n\n",
    "   perl -MCPAN -e'install \"LDS/GD-1.19.tar.gz\"'\n",
    "   perl -MCPAN -e'install \"N/NI/NINJAZ/Chart-0.99b.tar.gz\"'\n\n";
}
if (!$xmlparser) {
    print "만약 버그들을 다른 버그질라 설치본으로 방출(export)하거나 타 버그질라 설치본으로부터\n",
    "가져오기(import)하는 기능을 사용하시고 싶으시다면, 루트(root) 권한으로 XML::Parser\n",
    "모듈을 설치하셔야 합니다.\n\n",
    "   perl -MCPAN -e'install \"XML::Parser\"'\n\n";
}
if (%missing) {
    print "\n\n";
    print "버그질라가 옵셔널한 모듈들을 여러분의 시스템에서 발견하지 못하였거나, 시스템에\n",
    "설치된 모듈의 버전이 너무 오래된 것입니다.\n",
    "이들 모듈은 루트(root) 권한으로 다음과 같은 절차에 따라 설치하실 수 있습니다:\n";
    foreach my $module (keys %missing) {
        print "[NEED_MODULE]   perl -MCPAN -e 'install \"$module\"'\n";
        `perl -MCPAN -e 'install \"$module\"'`;
        if ($missing{$module} > 0) {
            print "  요구되는 최소 버전: $missing{$module}\n";
        }
    }
    print "\n";
    print "  필수 모듈 설치 후 진행 하시기 바랍니다.\n";
}
else
{
    print "  데이터 복구를 진행하셔도 됩니다.\n";
}

