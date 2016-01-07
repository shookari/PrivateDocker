#!/usr/bin/perl -w
# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# �� ������ ���빰�� ������ ���� ���̼��� ����(Mozilla Public License
# Version - ���� "���̼���") 1.1�� ���� ��ȣ�˴ϴ�. ���̼����� ������
# �ʴ� �������� �� ������ ����Ͻ� ���� �����ϴ�. ���̼����� ���� �纻��
# http://www.mozilla.org/MPL/ ���� ���Ͻ� �� �ֽ��ϴ�.
#
# MPL ���̼��� �Ͽ� �����Ǵ� ����Ʈ����� "�ִ� �״��" �����Ǵ� ����
# ��Ģ���� �մϴ�. ���� �� ����Ʈ����� ��������ε� ���������ε� ���� 
# ��� ������ ������ ���� �ʽ��ϴ�. ���Ѱ� ������׵鿡 ���� ���� �ڼ���
# ������ ���̼����� �����Ͻñ� �ٶ��ϴ�.
#
# ���� �ڵ�� �������� ���� ���� �ý���(Bugzilla Bug Tracking System)
# �Դϴ�.
#
# ���� �ڵ��� �ʱ� ������ "�ݽ������� Ŀ�´����̼� ���۷��̼�"���� ������ 
# ���� �Ӵϴ�. �� ��ǰ�� �Ϻ� �� Netscape �信 ���� ������� ���� Copyright
# (C) 1998 Netscape Communications Corporation�� ���� ��ȣ�Ǹ�, ��� 
# ������ Netscape�� �ֽ��ϴ�.
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

print "\nPerl ��� üũ...\n";
unless (eval "require 5.005") {
    die "�˼��մϴٸ�, ��� Perl 5.005 �̻��� �ʿ��մϴ�.\n";
}

# vers_cmp is adapted from Sort::Versions 1.3 1996/07/11 13:37:00 kjahds,
# which is not included with Perl by default, hence the need to copy it here.
# Seems silly to require it when this is the only place we need it...
sub vers_cmp {
  if (@_ < 2) { die "vers_cmp ȣ��� ������ �Ķ������ ������ �����մϴ�." }
  if (@_ > 2) { die "vers_cmp ȣ��� ������ �Ķ������ ������ �ʹ� �����ϴ�." }
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
  printf("��� üũ: %15s %-9s ", $pkg, !$wanted?'(any)':"(v$wanted)");

  eval { my $p; ($p = $pkg . ".pm") =~ s!::!/!g; require $p; };

  $vnum = ${"${pkg}::VERSION"} || ${"${pkg}::Version"} || 0;
  $vnum = -1 if $@;

  if ($vnum eq "-1") { # string compare just in case it's non-numeric
    $vstr = "ã�� ���߽��ϴ�.";
  }
  elsif (vers_cmp($vnum,"0") > -1) {
    $vstr = "v$vnum ��/�� �߰��Ͽ����ϴ�.";
  }
  else {
    $vstr = "�� �� ���� ������ �߰��Ͽ����ϴ�.";
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

print "\n���� Perl ������ �ɼų��Դϴ�:\n";
my $charts = 0;
$charts++ if have_vers("GD","1.19");
$charts++ if have_vers("Chart::Base","0.99");
my $xmlparser = have_vers("XML::Parser",0);

print "\n";
if ($charts != 2) {
    print "���� �׷��� ������ ���� ���Ӽ� ��Ʈ�� ���ñ� ���ϽŴٸ�, �߰������� libgb��\n",
    "Perl ����� GD-1.19 �� Chart::Base-0.99b�� ��Ʈ(root) �������� ��ġ�ϼž� �մϴ�.\n\n",
    "   perl -MCPAN -e'install \"LDS/GD-1.19.tar.gz\"'\n",
    "   perl -MCPAN -e'install \"N/NI/NINJAZ/Chart-0.99b.tar.gz\"'\n\n";
}
if (!$xmlparser) {
    print "���� ���׵��� �ٸ� �������� ��ġ������ ����(export)�ϰų� Ÿ �������� ��ġ�����κ���\n",
    "��������(import)�ϴ� ����� ����Ͻð� �����ôٸ�, ��Ʈ(root) �������� XML::Parser\n",
    "����� ��ġ�ϼž� �մϴ�.\n\n",
    "   perl -MCPAN -e'install \"XML::Parser\"'\n\n";
}
if (%missing) {
    print "\n\n";
    print "�������� �ɼų��� ������ �������� �ý��ۿ��� �߰����� ���Ͽ��ų�, �ý��ۿ�\n",
    "��ġ�� ����� ������ �ʹ� ������ ���Դϴ�.\n",
    "�̵� ����� ��Ʈ(root) �������� ������ ���� ������ ���� ��ġ�Ͻ� �� �ֽ��ϴ�:\n";
    foreach my $module (keys %missing) {
        print "[NEED_MODULE]   perl -MCPAN -e 'install \"$module\"'\n";
        `perl -MCPAN -e 'install \"$module\"'`;
        if ($missing{$module} > 0) {
            print "  �䱸�Ǵ� �ּ� ����: $missing{$module}\n";
        }
    }
    print "\n";
    print "  �ʼ� ��� ��ġ �� ���� �Ͻñ� �ٶ��ϴ�.\n";
}
else
{
    print "  ������ ������ �����ϼŵ� �˴ϴ�.\n";
}

