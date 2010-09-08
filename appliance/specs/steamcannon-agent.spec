%define ruby_version 1.8

Summary:        SteamCannon Agent
Name:           steamcannon-agent
Version:        0.0.1
Release:        1%{?dist}
License:        LGPL
Requires:       shadow-utils
Requires:       ruby git
Requires:       initscripts
Requires:       rubygems
BuildRequires:  ruby-devel gcc-c++ rubygems git sqlite-devel openssl-devel
Requires(post): /sbin/chkconfig
Group:          Development/Tools
Source0:        %{name}.init
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

# Ugly hack for thin
Provides:       /usr/local/bin/ruby

%description
SteamCannon Agent

%install
rm -rf $RPM_BUILD_ROOT

install -d -m 755 $RPM_BUILD_ROOT%{_initrddir}
install -m 755 %{SOURCE0} $RPM_BUILD_ROOT%{_initrddir}/%{name}

install -d -m 755 $RPM_BUILD_ROOT/usr/lib/ruby/gems/%{ruby_version}

/usr/bin/git clone git://github.com/steamcannon/steamcannon-agent.git $RPM_BUILD_ROOT/usr/share/%{name}

gem install --install-dir=$RPM_BUILD_ROOT/usr/lib/ruby/gems/%{ruby_version} --force --rdoc rack -v 1.2.0
gem install --install-dir=$RPM_BUILD_ROOT/usr/lib/ruby/gems/%{ruby_version} --force --rdoc $RPM_BUILD_ROOT/usr/share/%{name}/gems/thin-1.2.8.gem
gem install --install-dir=$RPM_BUILD_ROOT/usr/lib/ruby/gems/%{ruby_version} --force --rdoc sinatra dm-core dm-sqlite-adapter dm-migrations dm-is-tree json open4 rest-client

install -d -m 755 $RPM_BUILD_ROOT/var/log/%{name}
install -d -m 755 $RPM_BUILD_ROOT/var/lock
touch $RPM_BUILD_ROOT/var/lock/%{name}.pid

%clean
rm -rf $RPM_BUILD_ROOT

%post
/sbin/chkconfig --add %{name}

%files
%defattr(-,root,root)
/

%changelog
* Wed Sep 08 2010 Marek Goldmann 0.0.1-1
- Initial release
