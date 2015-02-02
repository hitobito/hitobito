### application settings
# add your specific settings here

%define app_name     RPM_NAME

%define app_version  1.6
%define ruby_version 1.9.3

### optional libs
# set things you need to 1
# if you need additional things
# please add conditionals like these

%define use_delayed_job 1
%define use_memcached   1
%define use_sphinx      1
%define use_imagemagick 1

%define bundle_without_groups 'development test metrics guard console'
%define exclude_dirs 'doc spec test vendor/cache log tmp Guardfile .rspec Wagonfile.ci rubocop-* db/production.sqlite3 bin/phantomjs'

# those are set automatically by the ENV variable used
# to generate the database yml
%if "%{?RAILS_DB_ADAPTER}" == "mysql2"
%define use_mysql       1
%else
%define use_mysql       0
%endif
%if "%{?RAILS_DB_ADAPTER}" == "postgresql"
%define use_pgsql       1
%else
%define use_pgsql       0
%endif
# TMP:
%define use_mysql       1

### end of application settings
### settings that should not be changed

%define wwwdir      /var/www/vhosts
%define ruby_bindir /opt/ruby-%{ruby_version}/bin
%define bundle_cmd  RAILS_ENV=production %{ruby_bindir}/bundle
%define build_number BUILD_NUMBER

##### start of the specfile
Name:		%{app_name}
Version:	%{app_version}.%{build_number}
Release:	1%{?dist}
Summary:	A web application to manage complex group hierarchies with members, events and a lot more.

Group:		Applications/Web
License:	AGPL
URL:		https://www.hitobito.ch
Source0:	%{name}-%{version}.tar.gz

BuildRequires:  opt-ruby-%{ruby_version}-rubygem-bundler
BuildRequires:  libxml2-devel
BuildRequires:  libxslt-devel
BuildRequires:  sqlite-devel
BuildRequires:  transifex-client
%if %{use_mysql}
BuildRequires:	mysql-devel
%endif
%if %{use_pgsql}
BuildRequires:	postgresql-devel
%endif
%if %{use_imagemagick}
BuildRequires: ImageMagick-devel
Requires: ImageMagick
%endif
%if %{use_sphinx}
Requires: sphinx
%endif
%if %{use_memcached}
Requires: memcached
%endif
Requires:	opt-ruby-%{ruby_version}-rubygem-passenger
Requires:	logrotate
Requires:	opt-ruby-%{ruby_version}
Requires:	opt-ruby-%{ruby_version}-rubygem-bundler
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-%(id -un)

%define appdir  %{wwwdir}/%{name}/www

%description

hitobito is an open source web application to manage complex group hierarchies with members, events and a lot more.


# == Build Scripts

%prep
# prepare the source to install it during the package building
# process.
%setup -q -n %{name}-%{version}


%build
# build/compile any code
# this can be left empty as for most rails applications we won't build
# any code.


%install
# Install the application code into the build root directory. This directory
# structure will be packaged into the package.
rm -rf $RPM_BUILD_ROOT

#### set env vars for database.yml
%if "%{?RAILS_DB_NAME}" != ""
  export RAILS_DB_NAME=%RAILS_DB_NAME
%endif
%if "%{?RAILS_DB_USERNAME}" != ""
  export RAILS_DB_USERNAME=%RAILS_DB_USERNAME
%endif
%if "%{?RAILS_DB_PASSWORD}" != ""
  export RAILS_DB_PASSWORD=%RAILS_DB_PASSWORD
%endif
%if "%{?RAILS_DB_HOST}" != ""
  export RAILS_DB_HOST=%RAILS_DB_HOST
%endif
%if "%{?RAILS_DB_PORT}" != ""
  export RAILS_DB_PORT
%endif
%if "%{?RAILS_DB_ADAPTER}" != ""
  export RAILS_DB_ADAPTER=%RAILS_DB_ADAPTER
%endif
### end setting vars

%if %{use_delayed_job}
install -Dp -m0755 config/rpm/workers.init $RPM_BUILD_ROOT/%{_initddir}/%{name}-workers
sed -i s/APP_NAME/%{name}/g $RPM_BUILD_ROOT/%{_initddir}/%{name}-workers
%endif

# this has to be deployed manually.
install -p -d -m0755 $RPM_BUILD_ROOT/%{_sysconfdir}/sysconfig
echo -e "#Ruby version to use\nRUBY_VERSION=%{ruby_version}" > $RPM_BUILD_ROOT/%{_sysconfdir}/sysconfig/%{name}

echo "%{app_version}.%{build_number}" > VERSION

mkdir $RPM_BUILD_ROOT/%{_sysconfdir}/logrotate.d
echo "# Rotate rails logs for %{name}
# Created by %{name}.rpm
%{appdir}/log/*.log {
  daily
  minsize 10M
  missingok
  rotate 7
  compress
  delaycompress
  notifempty
  copytruncate
}
" > $RPM_BUILD_ROOT/%{_sysconfdir}/logrotate.d/%{name}

%if %{use_sphinx}
touch config/production.sphinx.conf
mkdir $RPM_BUILD_ROOT/%{_sysconfdir}/cron.d
echo "# Reindex sphinx for %{name}
# Created by %{name}.rpm
10,25,40,55 * * * *  %{name}  cd %{appdir} && . %{wwwdir}/%{name}/.bash_profile && bundle exec rake ts:index > /dev/null 2>&1
" > $RPM_BUILD_ROOT/%{_sysconfdir}/cron.d/%{name}
%endif

export PATH=%{ruby_bindir}:$PATH
([ ! -f ~/.gemrc ] || grep -q no-ri ~/.gemrc) || echo "gem: --no-ri --no-rdoc" >> ~/.gemrc
%{bundle_cmd} install --path vendor/bundle --without %{bundle_without_groups}

RAILS_HOST_NAME='build.hitobito.ch' %{bundle_cmd} exec rake assets:precompile
RAILS_HOST_NAME='build.hitobito.ch' RAILS_GROUPS=assets %{bundle_cmd} exec rails generate error_pages

echo "[%{?RAILS_TRANSIFEX_HOST}]
hostname = %{?RAILS_TRANSIFEX_HOST}
password = %{?RAILS_TRANSIFEX_PASSWORD}
token =
username = %{?RAILS_TRANSIFEX_USERNAME}
" > ~/.transifexrc

RAILS_HOST_NAME='build.hitobito.ch' %{bundle_cmd} exec rake tx:pull tx:wagon:pull -t

# cleanup log and tmp we don't want them in the rpm
rm -rf log tmp
rm -f ~/.transifexrc
chmod -R o-rwx .

install -p -d -m0750 $RPM_BUILD_ROOT/%{appdir}
install -p -d -m0770 $RPM_BUILD_ROOT/%{appdir}/log
install -p -d -m0770 $RPM_BUILD_ROOT/%{appdir}/tmp
%if "%{?RAILS_DB_ADAPTER}" == "sqlite3"
install -p -d -m0770 $RPM_BUILD_ROOT/%{appdir}/db
%endif
%if "%{?RAILS_DB_ADAPTER}" == ""
install -p -d -m0770 $RPM_BUILD_ROOT/%{appdir}/db
%endif
# remove unnecessary files
for dir in %{exclude_dirs}; do
  [ -e $dir ] && rm -rf $dir
done
cp -p -r * $RPM_BUILD_ROOT/%{appdir}/
cp -p -r .bundle $RPM_BUILD_ROOT/%{appdir}/

%if %{use_sphinx}
install -p -d -m0755 $RPM_BUILD_ROOT/etc/sphinx
%endif

# fix shebangs
grep -sHE '^#!/usr/(local/)?bin/ruby' $RPM_BUILD_ROOT/%{appdir}/vendor/bundle -r | awk -F: '{ print $1 }' | uniq | while read line; do sed -i 's@^#\!/usr/\(local/\)\?bin/ruby@#\!/bin/env ruby@' $line; done


# == Install Scripts
#
# On upgrade, the scripts are run in the following order:
#
# %pretrans of new package
# %pre of new package
# (package install)
# %post of new package
# %triggerin of other packages (set off by installing new package)
# %triggerin of new package (if any are true)
# %triggerun of old package (if it's set off by uninstalling the old package)
# %triggerun of other packages (set off by uninstalling old package)
# %preun of old package
# (removal of old package)
# %postun of old package
# %triggerpostun of old package (if it's set off by uninstalling the old package)
# %triggerpostun of other packages (if they're setu off by uninstalling the old package)
# %posttrans of new package

%pre
# Run before the package is installed.
# Creates the user and group which will be used to run the
# application.
getent group %{name} > /dev/null || groupadd -r %{name}
getent passwd %{name} > /dev/null || \
  useradd -r -g %{name} -d %{wwwdir}/%{name} -s /sbin/nologin \
  -c "Rails Application %{name}" %{name}

if [ -d %{appdir} ] ; then
  touch %{appdir}/tmp/stop.txt
fi

%if %{use_delayed_job}
/sbin/service %{name}-workers stop >/dev/null 2>&1
%endif

exit 0


%post
# Runs after the package got installed.
# Configure here any services etc.

# the following old files would be loaded on startup and must
# be explicitly deleted to load the stop script
rm -f %{appdir}/app/utils/devise/strategies/one_time_token_authenticatable.rb
rm -f %{appdir}/app/utils/datetime_attribute.rb
rm -f %{appdir}/app/domain/event/qualifier/base.rb
rm -f %{appdir}/app/domain/event/qualifier/leader.rb
rm -f %{appdir}/app/domain/event/qualifier/participant.rb

su - %{name} -c "cd %{appdir}/; %{bundle_cmd} exec rake db:migrate db:seed wagon:setup -t" || exit 1

%if %{use_sphinx}
su - %{name} -c "cd %{appdir}/; %{bundle_cmd} exec rake ts:configure" || exit 1

ln -s %{appdir}/config/production.sphinx.conf /etc/sphinx/%{name}.conf || :
/sbin/chkconfig --add searchd || :
/sbin/service searchd condrestart >/dev/null 2>&1 || :
%endif

%if %{use_memcached}
/sbin/chkconfig --add memcached || :
(/sbin/service memcached status >/dev/null 2>&1 || \
  /sbin/service memcached start >/dev/null 2>&1) && /sbin/service memcached condrestart
%endif


%preun
# Run before uninstallation
# $1 will be 1 if the package is upgraded
# and 0 if the package is deinstalled.

%if %{use_delayed_job}
if [ "$1" = 0 ] ; then
  /sbin/service %{name}-workers stop > /dev/null 2>&1
  /sbin/chkconfig --del %{name}-workers || :
fi
%endif


%postun
# Run after uninstallation
# $1 will be 1 if the package is upgraded
# and 0 if the package is deinstalled.


%posttrans
%if %{use_delayed_job}
/sbin/chkconfig --add %{name}-workers || :
/sbin/service %{name}-workers restart >/dev/null 2>&1
%endif

touch %{appdir}/tmp/restart.txt
rm -f %{appdir}/tmp/stop.txt


%files
# describe all the files that should be included in the package
%defattr(-,root,root,)
%{_sysconfdir}/sysconfig/%{name}
%{_sysconfdir}/logrotate.d/%{name}
%if %{use_sphinx}
%{_sysconfdir}/cron.d/%{name}
%endif

%attr(-,root,%{name}) %{wwwdir}/%{name}/*
# run application as dedicated user
%attr(-,%{name},%{name}) %{appdir}/config.ru
# allow write access to special directories
%attr(0770,%{name},%{name}) %{appdir}/log
%attr(0770,%{name},%{name}) %{appdir}/public
%attr(0770,%{name},%{name}) %{appdir}/tmp
%attr(0770,%{name},%{name}) %{appdir}/db

%if %{use_delayed_job}
%{_initddir}/%{name}-workers
%endif

%if %{use_sphinx}
%attr(0660,%{name},%{name}) %{appdir}/config/production.sphinx.conf
%endif


%changelog
# veni
# vidi
# vici
