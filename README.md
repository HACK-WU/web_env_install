# web环境自动化源码安装脚本

* 此脚本可以实现LNMP和LAMP的自动化源码安装
* 也可以单独对其中的某一个软件进行源码安装。
* 此脚本安装PHP时，会自动对nginx或者httpd服务的配置文件进行更改，使其服务能够自动解析PHP文件，无需手动更改。
* 此脚本安装时，会自动进行启动脚本配置，安装完后，可用以下命令启动服务
  * service  mysqld start			启动mysqld服务
  * service  httpd  start	          启动httpd服务
  * service  php-fpm  start        启动PHP服务
* nginx的启动脚本，此脚本不进行配置，但脚本内容的能容就在上面名称为
  * init.d.nginx
  * 大家可以自行下载进行配置

# 适用系统

* Centos 7.6



# 适用的软件版本

* nginx:  nginx-1.22.0.tar.gz
* apache: httpd-2.4.54.tar.gz
* mysql:  mysql-5.7.39.tar.gz | mysql-boost-5.7.39.tar.gz
* php:    php-7.4.30.tar.gz



​	以上的软件版本，已经经过此脚本的安装测试，没有什么问题。大家可以放心使用。

​	值得注意的是，安装mysql时，请保持网路畅通，能够正常访问网络，因为安装mysql时，需要下载一个boost模块，如果不能访问网络，将会报错。



>  如果大家安装mysql时，遇到以下问题，就是网络的问题。检查网络，再次运行此脚本即可。

![image-20220823183454990](https://hackwu-images-1305994922.cos.ap-nanjing.myqcloud.com/images/image-20220823183454990.png)

​	

>  当然了，如果大家想用此脚本安装其他版本的软件，也是可以的。只需要按照自己的需求，更改此脚本中，对应软件的配置，即可.



# 使用方法

* 首先需要下载好对应版本的源码包。

  ```shell
  wget https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-5.7.39.tar.gz		#mysql-5.7.39.tar.gz 下载
  或
  wget https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-boost-5.7.39.tar.gz #mysql-boost-5.7.39.tar.gz下载
  wget https://downloads.apache.org/httpd/httpd-2.4.54.tar.gz		#httpd-2.4.54.tar.gz 下载
  wget http://nginx.org/download/nginx-1.22.0.tar.gz				#nginx-1.22.0.tar.gz 下载
  wget https://www.php.net/distributions/php-7.4.30.tar.gz		#/php-7.4.30.tar.gz 下载
  ```

* 修改脚本

  > 比如，现在要部署LNMP环境，还需要将MYSQL_TAG,NGINX_TAG,PHP_TAG 的值设为ON，即可。
  >
  > 不需要安装的设为OFF，表示不安装。
  >
  > 然后将对应的软件包位置的绝对路径写在对应的pkg后面即可，如下示例：

  ``` shell
  vim LNMP_install.sh
  .......
  
  MYSQL_TAG=ON
  NGINX_TAG=ON                                    #是否开启安装功能，ON为开启，OFF为不开启
  Apache_TAG=OFF
  PHP_TAG=ON
  
  NGINX_pkg=/root/nginx-1.22.0.tar.gz                     #nginx的源码包包位置，绝对路径
  Apache_pkg=       										#apache源码包                             
  MYSQL_pkg=/root/mysql-5.7.39.tar.gz                     #mysql的源码包位置，绝对路径
  PHP_pkg=/root/php-7.4.30.tar.gz
  ```

* 软件的编译配置，脚本中已经默认编写好了，如果需要更改配置，也可以自行修改

  > 如下显示，
  >
  > MYSQL_user=mysql                是指定了运行mysql的用户，为mysql用户
  >
  > MYSQL_basedir=/usr/local/mysql  是指定了软件的安装目录
  >
  > MYSQL_cmake=""            是指定了mysql的编译配置。
  >
  > NGINX_configure=""        是指定了nginx的编译配置

  ![image-20220823185912045](https://hackwu-images-1305994922.cos.ap-nanjing.myqcloud.com/images/image-20220823185912045.png)



* 最后运行脚本，静静等待即可。

* 如果用脚本安装了mysql，会产生一个临时文件mysql_passwd，里面纪录了MySQL的随机初始密码，

  可自行查看.

  ```shell
  cat /tmp/mysql_passwd
  ```

  ![image-20220823190955349](https://hackwu-images-1305994922.cos.ap-nanjing.myqcloud.com/images/image-20220823190955349.png)

> 上图红色框，标记的就是mysql的初始密码，具体的密码，需要查看自己mysql_passwd文件，每个人的都不一样。

* 测试，

  ```shell
  service nginx start
  service php-fpm start
  
  # 最后在浏览器上访问服务器地址，即可。
  ```

  
