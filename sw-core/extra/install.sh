#!/bin/sh

echo "#######################################################################"
echo "#   You might notice that Apache::Filter fails some tests, that is    #"
echo "#   because it attempts to start a httpd server to preform live tests #"
echo "#   and if it doesn't find it, the tests fails.                       #"
echo "#######################################################################"

for module in *.tgz; do
	echo Installing custom version of $module  
	tar -zxvf $module > /dev/null
	DIR=`echo $module | sed -e s/\.[^.]*$//`
	cd $DIR
	perl Makefile.PL
	make
	make test
	make install
	cd ..
	rm -rf $DIR
done
