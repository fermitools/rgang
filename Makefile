#  This file (makefile) was created by Ron Rechenmacher <ron@fnal.gov> on
#  Jun 20, 2001. "TERMS AND CONDITIONS" governing this file are in the README
#  or COPYING file. If you do not have such a file, one can be obtained by
#  contacting Ron or Fermi Lab in Batavia IL, 60510, phone: 630-840-3000.
#  $RCSfile: Makefile,v $
#  $Revision: 1.40 $
#  $Date: 2024/12/19 21:39:25 $

# NOTE: freeze utility is from python distribution directory tree; not
#       the installation tree.
# Note: when making frozen, if you get the warning "unknown modules remain"
#       and the list contains more then "pcre strop"
#       then you may have to rebuild python after uncommenting something in
#       the python distribution's Modules/Setup file.
#PYDIST_V=2.2.3
#PYDIST_V=2.5.2 # could not get to work 2010.05.07 from tststnd2.fnal.gov -
#                fall back to 2.2.3
#PYDIST_V=2.4.3
PYDIST_V=2.4.6
UPS_PY_V := v$(shell echo ${PYDIST_V} | sed 's/\./_/g')
SYS_PY_V :=  $(shell echo ${PYDIST_V} | grep -o '^[0-9]\.[0-9]')

default:
	@echo make targets are: `grep '^[a-z]*:' Makefile`

.PHONY: rpm
rpm:
	$(MAKE) -C $@ $@
	@echo Done with rpm

frozen:
	if [ -f /usr/lib/python${SYS_PY_V}/Tools/freeze/freeze.py ];then\
	    PYDIST=/usr/lib/python${SYS_PY_V};\
	elif [ -f /usr/local/etc/setups.sh ];then\
	    . /usr/local/etc/setups.sh; setup python ${UPS_PY_V};\
            if [ -d /p/python/Python-${PYDIST_V} ];then\
	        PYDIST=/p/python/Python-${PYDIST_V};\
	        export PYDIST;\
	    fi;\
	fi;\
	if [ "$$PYDIST" = "" ];then\
	    echo "PYDIST variable not set; unable to make frozen rgang";\
	    exit 1;\
	fi;\
	cd bin;\
	type python;\
	python $$PYDIST/Tools/freeze/freeze.py rgang.py;\
	make && strip rgang

tar:
	@if [ -d CVS ];then\
	    product=rgang;\
	    echo "I hope you remembered to:";\
echo "    o make sure debugging if in main() is set correctly (\"if 1:\")";\
echo "    o update README: version and date";\
echo "    o update bin/rgang.py version to be same as version in README";\
echo "    o cvs ci -m'some message' bin/rgang.py # so frozen is synced with .py";\
echo "    o make frozen distclean";\
echo "    o test: cd test;./test.sh most";\
echo "    o cvs -q up;cvs ci changed file to get good comments in release notes";\
echo "    o updated doc/RELEASE.NOTES:";\
echo "         next_rev=vX_Y_Z   # i.e. v3_8_0";\
echo "         doc/cvs_rel_notes.sh --update_REL_NOTES \$$next_rev";\
echo "         # message/edit the release notes file";\
echo "    o update rpm/rgang.spec changelog and version to be same as version in README";\
echo "    o cvs ci -m\"next rev (rev \$$next_rev)\" # for release notes";\
echo "and o cvs tag \$$next_rev";\
echo "And the <version>s specified match the version in the README.";\
echo "You quite possibly will be entering that version in response to";\
echo "the next question";\
	    CVSROOT=`cat CVS/Root`; export CVSROOT;\
	    if [ "$(TAG)" = "" ];then \
	        echo -n "enter a tag (or abort now) (\"HEAD\" is valid): "; read ans;\
	    else \
	        ans=$(TAG);\
	    fi;\
	    if [ ! "$$ans" ];then exit 1;fi;\
	    dot_ver=`echo $$ans | sed -e 's/^v//;s/_/./g'`;\
	    for ff in bin/rgang.py README;do \
	        version=`sed -n -e"/V[eE][rR][sS][iI][oO][nN][:=]/{s/.*V[eE][rR][sS][iI][oO][nN][=:][' ]*//;s/ .*//;p;}" $$ff`;\
	        if [ "$$version" != $$dot_ver ];then \
	            echo "updating version=$$version in $$ff";\
                    need_human_check=1;\
	            sed -e"/V[eE][rR][sS][iI][oO][nN][:=]/s/$$version/$$dot_ver/" -e"/^Date /s|:.*|:      `date +%m/%d/%Y`|" $$ff >$$ff.xx;\
	            mv $$ff.xx $$ff;\
	        fi;\
            done;\
	    if [ "$${need_human_check-}" ];then \
	        cvs -nq up | grep -v '^?';\
	        echo "renew the changes: cvs -q diff";\
	        echo "and, if appropriate: cvs ci -m'new rev'";\
	        exit;\
	    fi;\
	    tmpdir=/tmp;\
	    cd $$tmpdir;\
	    if [ -d $$product.$$ans ];then\
	        echo "removing (old/bogus?) $$tmpdir/$$product.$$ans directory";\
	        /bin/rm -fr $$product.$$ans;\
	    fi;\
	    if [ -f $$product.$$ans.tar ];then\
	        echo "removing (old/bogus?) $$tmpdir/$$product.$$ans.tar file";\
	        /bin/rm -fr $$product.$$ans;\
	    fi;\
	    cvs export -r $$ans -d $$product.$$ans $$product;\
	    tar cf $$product.$$ans.tar $$product.$$ans;\
	    tar czf $$product.$$ans.tgz $$product.$$ans;\
	    echo "tar file is $$tmpdir/$$product.$$ans.tar";\
	    echo "tgz file is $$tmpdir/$$product.$$ans.tgz";\
	    echo "After installing the product locally:";\
	    echo "   mv /tmp/rgang.$$ans.* /p/rgang";\
	    echo "   mv /tmp/rgang.$$ans /p/rgang/$$ans";\
            echo "   ups_flavor.sh --ups /p/rgang/$$ans";\
	    echo "   ups declare -c -rrgang/$$ans -f<flavor> -mrgang.table rgang $$ans";\
	    echo "do:";\
	    echo "   upd addproduct -c rgang $$ans -f<flavor>";\
	else\
	    echo "this should be done from within a cvs checked-out tree";\
	fi


clean:
	find . -name '*~' -exec rm {} \;
	cd bin; rm -f *~ *.o rgang

# leave frozen rgang
distclean:
	find . -name '*~' -exec rm {} \;
	cd bin; rm -f *.o M_* Makefile config.c frozen.c

