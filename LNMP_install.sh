#!/bin/bash
########################################
# Author:hackwu
# time:2022年08月21日 星期日 18时09分38秒
# filename:LNMP_install.sh
# Script description:
#
# 适用的软件版本：
#	nginx:  nginx-1.22.0.tar.gz
#   mysql:  mysql-boost-5.7.39.tar.gz(推荐) | mysql-5.7.39.tar.gz| mysql-5.7.39-linux-glibc2.12-x86_64
#	php:
########################################

set -u
#set -e

# yum intall openssl-devel  gcc gcc-c++		#安装编译工具



function tar_xf {    
#	 参数：
#		$1:软件包的绝对路径
#		$2:运行软件的用户名	

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
	tar xf $pkg
	pkgdir=$basedir${pkg/.tar.gz/""}/	#解压后的目录名
	pkgdir=${pkgdir/-boost/""}	#解压后的目录名
	if [ ! -d $pkgdir  ];then
		echo "$pkgdir 不是一个目录！"
		echo "注意，软件压缩包是一个绝度路径"
		exit 1
	fi

	echo "$pkgdir"				#返回解压后的目录名
}

function install_pkg {
#	参数：
#		$1:		软件包的解压目录
#		$2:		软件的编译配置		
	local pkgdir=$1
	local configure=$2
	
	cd $pkgdir			
	local prefix=$(echo $configure | cut  -d " "  -f 1 )
	local prefix=${prefix#*--prefix=}

	cd $pkgdir
	
	if [ "$configure" != "null"  ];then
		./configure $configure 
		if [ ! "$?" -eq 0  ];then
			echo "configure 发生错误！！"
			exit 1	
		fi		
	fi

	make -j4&&make install		
	if [ "$?" -eq 0 ];then
		echo
		echo "安装成功！"
		echo "安装目录：$prefix"
		cd $prefix
		pwd
		ls -l $prefix
		return 0
	else
		echo "编译或安装出错"
		exit 1
	fi

}

######################  NGINX ################################
#yum -y install pcre-devel zlib-devel  #安装nginx依赖
#pkg=/root/nginx-1.22.0.tar.gz
#configure="--prefix=/usr/local/nginx  --user=www --group=www --with-http_stub_status_module --with-http_ssl_module"
#install_pkg  $(tar_xf $pkg www )  $configure

#######################Mysql ###########################
function init_mysql {    #mysql初始化
#	参数：
#		$1:  安装目录
#		$2:  运行mysql的用户名
#	yum install libaio 
	local prefix=$1			#安装目录
	local user=$2			#用户
	
	useradd -r -s /sbin/nologin $user

	cd $prefix
	rm -f /etc/my.cnf	
	mkdir mysql-files
	chown  -R  $user:$user mysql-files
	chmod 750 mysql-files
#	chown $user:$user $prefix	
	bin/mysqld --initialize --user=$user
	if [ "$?" -ne 0  ];then
		echo -e  "\033[31m数据库初始化失败\033[0m"
		exit 0

	fi
	cp  $prefix/support-files/mysql.server  /etc/init.d/mysqld
	prefix=${prefix//'/'/'\/'}
	sed -i  -e "s/basedir=/basedir=$prefix/g;s/datadir=/datadir=$prefix\/data/g" /etc/init.d/mysqld
	
	service mysqld start
	[ "$?" -eq 0  ]&& echo "数据库启动成功！！" || echo "数据库启动失败"
}

function install_mysql {

#yum -y install bison   ncurses-devel cmake libaio-devel 	#安装依赖

dd if=/dev/zero of=/swapfile bs=1M count=2048       	#创建交换分区
mkswap /swapfile 
swapon /swapfile

local pkg=/root/mysql-boost-5.7.39.tar.gz
#tar_xf $pkg mysql
local pkgdir=$( tar_xf $pkg "mysql" )

if [[ "$pkgdir" =~ 注意  ]];then
	echo -e "\033[31m$pkgdir 不是一个目录！\033[0m"
	exit 1
fi

cd $pkgdir
cmake . \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_DATADIR=/usr/local/mysql/data \
-DMYSQ_TCP_PORT=3306 \
-DMYSQL_UNIX_ADDR=/usr/local/mysql/mysql.sock \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8mb4 \
-DDEFAULT_COLLATION=utf8mb4_general_ci \
-DWITH_SSL=system \
-DWITH_BOOST=/usr/local/mysql/boost \
-DDOWNLOAD_BOOST=1 

if [ "$?" -eq 0 ];then
	install_pkg  $pkgdir null		#进入到软件包目录
	
	swapoff /swapfile			#删除交换分区  
	rm -f /swapfile
		
else
	echo "cmake 发生错误"
	exit 1
fi

}

# install_mysql
init_mysql "/usr/local/mysql"  mysql
