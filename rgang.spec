#!/bin/sh
%define vers 3.9.5
%define lname rgang
%define source0 ./%{lname}-%{vers}.tar.gz

Name: fermilab-util_%{lname}
Summary: Parrallel execution of a command on, or copying of a file.
Version: %{vers}
# "Release" is the "version" of the rpm (not the software in the rpm)
Release: 0%{?dist}
License: Fermitools
Group: Applications/System
Source0: %{source0}
BuildArch: noarch
BuildRequires: python3 python3-devel
Requires: python3

URL: http://servicedesk.fnal.gov

%description
RGANG is a tool which allows one to execute commands on or distribute
files to many nodes (computers). It incorporates an algorithm to build a
tree-like structure (or "worm" structure) to allow the distribution
processing time to scale very well to 1000 or more nodes. When executing
a command, output is buffered and presented in node specification order.

%prep
%setup -c -n %{name}-%{version}

%build

%install
if [[ $RPM_BUILD_ROOT != "/" ]]; then
    %{__rm} -rf $RPM_BUILD_ROOT
fi
%{__install} -D doc/rgang.8 ${RPM_BUILD_ROOT}/%{_mandir}/man8/rgang.8

%{__install} -D ./bin/rgang.py ${RPM_BUILD_ROOT}/%{python3_sitelib}/rgang.py
%{__mkdir_p} ${RPM_BUILD_ROOT}/%{_exec_prefix}/bin

%{__ln_s} %{python3_sitelib}/rgang.py ${RPM_BUILD_ROOT}/%{_exec_prefix}/bin/rgang


%clean
if [[ $RPM_BUILD_ROOT != "/" ]]; then
    %{__rm} -rf $RPM_BUILD_ROOT
fi

%files
%defattr(-,root,root)
%doc README doc/RELEASE.NOTES rgang_examples.txt
%{_mandir}/man8/rgang*
%{_exec_prefix}/bin/rgang
%{python3_sitelib}/*


%changelog
* Mon Dec 08 2025   Ron Rechenmacher <ron@fnal.gov> 3.9.5
- replaced re.sub(this,that,istr,0) with re.sub(this,that,istr,count=0)
- bumped version

* Tue Jan 14 2025   Ron Rechenmacher <ron@fnal.gov> 3.9.4
- change script shebang from "/usr/bin/env python" to "/bin/env python3"
- change default rsh/rcp to ssh/scp
- python2/3 compatible
- add verbose logging messages
- fixed nodespec processing

* Thu Apr 07 2016   Ron Rechenmacher <ron@fnal.gov> 3.8.0
- better handling of files in node specification

* Thu Nov 21 2013   Connie Sieh <csieh@fnal.gov>  3.4-2
- Made the spec file generic.  Removed the references to CMS
- Changed the rsync to a cp so we are not dependent on rsync

* Mon Jun 10 2013   Tim Skirvin <tskirvin@fnal.gov>  3.4-1
- re-working the .spec file
- added a man page, docs are installing into /usr/share/docs

* Mon Jun 10 2013   Lisa Giachetti <lisa@fnal.gov>  3.4-1
- Made version prior to 3.4-1 

* Mon Jun 10 2013  Ron Rechenmacker   3.4
- Author of rgang 
