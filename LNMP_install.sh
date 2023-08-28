#!/bin/bash
###########################################################################################################
# Author:hackwu.
# email:2013743179@qq.com
# time:2022年08月21日 星期日 18时09分38秒
# filename:LNMP_install.sh
# Script description:
#
# 适用的软件版本：
#	nginx:  nginx-1.22.0.tar.gz
#	apache:	httpd-2.4.54.tar.gz
#   mysql:  mysql-boost-5.7.39.tar.gz(推荐) | mysql-5.7.39.tar.gz
#	php:    php-7.4.30.tar.gz
#	
#	说明：
#		1、本脚本经过测试，完全适用于以上四个版本的自动安装使用。
#		2、如果想尝试其版本的自动化安装，也可以试试。
#	
#	使用说明：
#		1、NGINX_TAG,为是否开启安装功能的开关，如果为ON，则为开启的意思。
#		2、MYSQL_pkg,是mysql源码包位置的绝对路径。
#		3、所以若要实现LNMP环境的安装，只需要同时将三个软件的安装功能都开启即可。
#		4、本脚本也支持实现LAMP的环境安装，只需要设置Apache_TAG=ON即可。
#		5、配置好源码包的绝对路径和开启对应软件的安装选项后，直接运行此脚本即可。
#		6、此脚本安装完成PHP后，会自动修改NGINX或者Apache的配置文件，使其能够解析PHP文件，无需手动更改。
#		7、此脚本会自动配置mysql,apache,php的启动脚本
#			service httpd   start		启动httpd
#			service mysqld  start       启动mysqld
#			service php-fpm start		启动php
###########################################################################################################
set -u
#set -e

MYSQL_TAG=ON
NGINX_TAG=OFF					#是否开启安装功能，ON为开启，OFF为不开启
Apache_TAG=ON
PHP_TAG=ON

NGINX_pkg=										#nginx的源码包包位置，绝对路径
Apache_pkg=/root/httpd-2.4.54.tar.gz												#apache源码包
MYSQL_pkg=/root/mysql-5.7.39.tar.gz				#mysql的源码包位置，绝对路径
PHP_pkg=/root/php-7.4.30.tar.gz							#php源码包位置

##############################   软件安装配置     #############################################
NGINX_user=www							#运行软件的用户
NGINX_basedir=/usr/local/nginx
NGINX_configure="--prefix=$NGINX_basedir  --user=$NGINX_user --group=$NGINX_user \
--with-http_stub_status_module --with-http_ssl_module"

MYSQL_user=mysql						#运行软件的用户
MYSQL_basedir=/usr/local/mysql			#mysql的安装位置
MYSQL_boost=" -DDOWNLOAD_BOOST=1"
MYSQL_cmake=" -DCMAKE_INSTALL_PREFIX=$MYSQL_basedir \
-DMYSQL_DATADIR=$MYSQL_basedir/data \
-DMYSQ_TCP_PORT=3306 \
-DMYSQL_UNIX_ADDR=$MYSQL_basedir/mysql.sock \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8mb4 \
-DDEFAULT_COLLATION=utf8mb4_general_ci \
-DWITH_SSL=system -DWITH_BOOST=$MYSQL_basedir/boost \
-DDOWNLOAD_BOOST=1
"

#################
Apache_user=httpd
Apache_basedir=/usr/local/apache2
Apache_configure="--prefix=$Apache_basedir \
--enable-modules=all \
--enable-mods-shared=all \
--enable-so \
--enable-rewrite \
--with-pcre \
--enable-ssl \
--with-mpm=prefork \
--with-apr=/usr/bin/apr-1-config \
--with-apr-util=/usr/bin/apu-1-config
"

################
PHP_user=www						   #运行软件的用户
PHP_basedir=/usr/local/php			   #软件安装位置:
PHP_apache_conf=" --with-apxs2=$Apache_basedir/bin/apxs --enable-opcache"
PHP_configure="--prefix=$PHP_basedir --with-config-file-path=$PHP_basedir/etc/ \
--with-libxml-dir  --with-jpeg-dir  --with-png-dir  \
--with-freetype-dir=/usr/local/freetype/  \
--with-mysqli=$MYSQL_basedir/bin/mysql_config --with-iconv-dir \
--enable-mbstring=all   --with-zlib  --with-libzip --with-curl \
--enable-sockets   --enable-xml --enable-sysvsem   --enable-bcmath  \
--with-pdo-mysql=$MYSQL_basedir   --with-fpm-group=$PHP_user  \
--with-gd --without-pear    --with-gettext --enable-soap \
--enable-fpm  --with-fpm-user=$PHP_user   --with-openssl --with-mhash \
--enable-ftp --enable-maintainer-zts  --with-xmlrpc  --enable-pcntl \
--enable-inline-optimization  --enable-shmop --enable-mbregex  
"
[ "$Apache_TAG" == "ON"  ]&& PHP_configure="$PHP_configure $PHP_apache_conf"

####################################################################################3
 yum install -y epel-release.noarch
 yum install -y  openssl-devel  gcc gcc-c++		#安装编译工具


function tar_xf {    
#	 参数：
#		$1:软件包的绝对路径
#		$2:运行软件的用户名	
#	 只能有一个echo : 解压目录的绝对路径

	local pkg=$1		 	#软件包名称
	local user=$2			#运行的用户名
	
	if [[ ! "$1" =~ .tar.gz  ]];then
		echo "软件包格式错误"
		echo -e  "请使用\033[31m.tar.gz\033[0m格式的软件包"
		exit 1
	fi

	useradd -r -s /sbin/nologin $user		#创建对应的系统用户
	local basedir=${pkg%/*}/
	local pkg=${pkg##*/}
	cd $basedir
	tar -xf $pkg
	pkgdir=$basedir${pkg/.tar.gz/""}/	#解压后的目录名
	pkgdir=${pkgdir/-boost/""}	#解压后的目录名
	if [ ! -d $pkgdir  ];then
		echo "$pkgdir 不是一个目录！"
		echo "注意，软件压缩包是一个绝度路径"
		exit 1
	fi

	echo "$pkgdir"				#返回解压后的目录名
}


PKG_DIR=null
function install_pkg {
#	参数：
#		$1:		软件包的解压目录
#		$*:		软件的编译配置		
	local pkgdir=$1
	shift
	local configure=$*
	
	PKG_DIR=$pkgdir
	cd $pkgdir			
	local prefix=$(echo $configure | cut  -d " "  -f 1 )
	local prefix=${prefix#*--prefix=}

	if [ "$configure" != "null"  ];then
		./configure $configure 
		if [ ! "$?" -eq 0  ];then
			echo "configure 发生错误！！"
			exit 1	
		fi		
	fi
		
	dd if=/dev/zero of=/swapfile bs=1M count=2048      	#创建交换分区
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile

	make -j4 && make install		
	if [ "$?" -eq 0 ];then
		swapoff /swapfile			#删除交换分区  
		rm -f /swapfile
		
		echo
		echo "安装成功！"
		echo "安装目录：$prefix"
		cd $prefix
		pwd
		ls -l $prefix
		return 0
	else	
		swapoff /swapfile			#删除交换分区  
		rm -f /swapfile
		echo "编译或安装出错"
		exit 1
	fi

}

#######################Mysql ###########################
function init_mysql {    #mysql初始化
#	参数：
#		$1:  安装目录
#		$2:  运行mysql的用户名
#	yum install libaio 
	local prefix=$1			#安装目录
	local user=$2			#用户
    tmpfile=/tmp/mysql_passwd
	useradd -r -s /sbin/nologin $user

	cd $prefix
	rm -f /etc/my.cnf	
	mkdir mysql-files
	chown   $user:$user mysql-files
	chmod 750 mysql-files
	chown -R  $user:$user $prefix	
	bin/mysqld --initialize --user=$user  --basedir=$prefix &> $tmpfile
	cat /tmp/mysql_passwd
	if [ "$?" -ne 0  ];then
		echo -e  "\033[31m数据库初始化失败\033[0m"
		exit 0

	fi
	rm -fr /etc/init.d/mysqld
	cp  $prefix/support-files/mysql.server  /etc/init.d/mysqld
	prefix=${prefix//'/'/'\/'}
	sed -i  -e "41,49 s/basedir=/basedir=$prefix/g;41,49 s/datadir=/datadir=$prefix\/data/g" /etc/init.d/mysqld
	
	service mysqld start
	if [  "$?" -eq 0  ];then
		
		 echo "数据库安装成功！！!" >> $tmpfile
		 echo "若此密码无法的登录数据库，可以先跳过授权表：
				source /etc/profile
				service mysqld start --user=root --skip-grant-tables
				mysql
			
				就可以登录，登录之后，更改mysql.user表改密码。" >> $tmpfile
 
		 service mysqld stop
		 echo "export PATH=\$PATH:$prefix/bin" >> /etc/profile
		 echo -e  "\033[33m请执行source /etc/profile 命令\033[0m"
	else
		 echo "数据库启动失败"
	fi
}

function install_mysql {
#	参数：
#		$1: 软件包的绝对路径
#		$2: 运行软件的用户名
#		$*: cmake配置
yum -y install bison   ncurses-devel cmake libaio-devel 	#安装依赖

local pkg=$1
local user=$2
shift
shift
local cmake=$*
tar_xf $pkg $user

local pkgdir=$( tar_xf $pkg $user )

if [[ "$pkgdir" =~ 注意  ]];then
	echo -e "\033[31m$pkgdir 不是一个目录！\033[0m"
	exit 1
fi

cd $pkgdir
cmake $cmake

if [ "$?" -eq 0 ];then
	install_pkg  $pkgdir null		#进入到软件包目录	
	return 0		
else
	echo "cmake 发生错误"
	exit 1
fi

}

function mysql_main {
	local pkg=$MYSQL_pkg
	local user=$MYSQL_user
	local basedir=$MYSQL_basedir
	local cmake=$MYSQL_cmake
	install_mysql  $pkg $user $cmake	#编译安装软件包
	init_mysql $basedir  $user			#初始化数据库
}

[ "$MYSQL_TAG" == "ON"  ] && mysql_main

######################  NGINX ################################
function nginx_main {
	yum -y install pcre-devel zlib-devel  #安装nginx依赖
	local pkg=$NGINX_pkg
	local user=$NGINX_user
	local configure=$NGINX_configure
	install_pkg  $(tar_xf $pkg $user )  $configure
}

[ "$NGINX_TAG" == "ON"  ] && nginx_main

#####################  apache   #########################
function init_httpd {
	local basedir=$1	
echo "#!/usr/bin/bash
. /etc/init.d/functions
EXEC=$1/bin/apachectl
case \$1 in
start)  bash \$EXEC    \$1  ;;
stop)  bash \$EXEC -k   \$1  ;;
restart)  bash \$EXEC  -k   \$1  ;;
status) systemctl status httpd ;;
* )
    echo 'please enter start|stop|restart|status' ;;
esac
" > /etc/init.d/httpd
chmod a+x /etc/init.d/httpd

sed -i  "/#ServerName www.example.com/ c ServerName localhost:80" $basedir/conf/httpd.conf

local basedir=$basedir/conf/httpd.conf
cp $basedir{,.bak}	#文件备份
str='LoadModule negotiation_module modules\/mod_negotiation.so'
sed  -i  "/$str/ c $str" $basedir

str='Include conf\/extra\/httpd-languages.conf'
sed  -i  "/$str/ c $str" $basedir
str='LoadModule php7_module modules\/libphp7.so'
sed -i "166 a  $str " $basedir
str='#AddType application\/x-gzip'
str1="    AddType text\/html .php"
sed -i "/$str/ a $str1 " $basedir
str1="    AddHandler php7-script php"
sed -i "/$str/ a $str1 " $basedir

str="DirectoryIndex index.html"
str1="DirectoryIndex index.php index.html"
sed -i "/$str/ c  $str1" $basedir
}

function install_httpd {
#	参数
#		$1:	源码包的绝对路径
#		$2: 用户
#		$*: 配置参数

	yum install -y apr-util-devel-1.5.2-6.el7.x86_64  apr-devel-1.4.8-7.el7.x86_64 #安装依赖
	
	local pkg=$1
	local user=$2
	shift
	shift
	local configure=$*

	install_pkg $( tar_xf $pkg  $user ) $configure	
}

function apache_main {
	local pkg=$Apache_pkg
	local user=$Apache_user
	local basedir=$Apache_basedir
	local configure=$Apache_configure
	install_httpd  $pkg $user  $configure
	init_httpd  $basedir
}

[ "$Apache_TAG" == "ON"  ] && apache_main


################################# php ##################################
 function init_php {
#   参数
#       $1:  安装路径
#       $2:  解压后的软件包位置

    local prefix=$1
    local pkgdir=$2
    cp $prefix/etc/php-fpm.conf.default $prefix/etc/php-fpm.conf
    cp $prefix/etc/php-fpm.d/www.conf.default $prefix/etc/php-fpm.d/www.conf
    cp $pkgdir/php.ini-development $prefix/etc/php.ini
    ln -s $prefix/bin/* /usr/local/bin/
    ln -s $prefix/sbin/* /usr/local/sbin/
    cp $pkgdir/sapi/fpm/init.d.php-fpm    /etc/init.d/php-fpm
	chmod a+x /etc/init.d/php-fpm	
}

function conf_web {
	local web_basedir=$1
	function conf_nginx {
		local conf=$1/conf/nginx.conf	
	    local num=$( grep -n   "pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000" $conf | cut -d ":" -f 1   )
	    local start=$((num+2 ))
	    local  end=$((num+8))
		echo $start
		echo $end
	    sed -i  "$start,$end s/#//g" $conf &>/dev/null
	
	    let end=end-1
	    sed  -i "$end s/fastcgi_params/fastcgi.conf/g" $conf  &>/dev/null
	echo "<?php
			phpinfo();
	?>
	" > $1/html/index.php
	}

	function conf_httpd {
		local conf=$1
	echo "<?php
			phpinfo();
	?>
	" > $1/htdocs/index.php
	}

	[ "$NGINX_TAG" == "ON"  ]&& conf_nginx $web_basedir 
	[ "$Apache_TAG" == "ON" ]&& conf_httpd $web_basedir
	
}



function install_php {
#  参数：
#	$1:  软件包绝对路径
#	$2： 运行软件的用户
#	$*:	 编译配置
yum -y install libxml2-devel libjpeg-devel libpng-devel freetype-devel curl-devel openssl-devel sqlite-devel oniguruma oniguruma-devel

   local pkg=$1
   local user=$2
   shift
   shift
   local configure=$*
   install_pkg $(tar_xf  $pkg $user ) $configure

}

function php_main {
	local pkg=$PHP_pkg
	local user=$PHP_user
	local basedir=$PHP_basedir
	local configure=$PHP_configure
	install_php $pkg  $user  $configure
	init_php $basedir  $PKG_DIR
	[ "$NGINX_TAG" == "ON"  ]&& conf_web $NGINX_basedir 
	[ "$Apache_TAG" == "ON" ]&& conf_web $Apache_basedir
}

[ "$PHP_TAG" == "ON"  ] && php_main

[ "$MYSQL_TAG" == "ON" ] && cat $tmpfile
