### Hadoop-Docker集群部署步骤
#### 1. 下载Hadoop和jdk
先在主机下载后复制到容器中，在容器中下载速度比较慢
下载hadoop-2.8.1 和jdk-8u201-linux-x64.tar.gz
```
RUN curl -LO 'https://download.oracle.com/otn-pub/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/jdk-8u201-linux-x64.tar.gz' -H 'Cookie: oraclelicense=accept-securebackup-cookie'
RUN tar -zxvf jdk-8u201-linux-x64.tar.gz && mv jdk1.8.0_201/ /usr/local/jdk
```
```
RUN curl -LO 'http://archive.apache.org/dist/hadoop/common/hadoop-2.8.1/hadoop-2.8.1.tar.gz' 
RUN tar -zxvf hadoop-2.8.1.tar.gz  && /usr/local/
```
将下载后的压缩包放在config目录下
#### 2. 构建镜像
```
docker build -t jp6907/hadoop-base .
```

#### 3. 创建容器
```
docker run --name="hdp-01" --hostname=hdp-01 -p 50070:50070 -it jp6907/hadoop-base
docker run --name="hdp-02" --hostname=hdp-02 -it jp6907/hadoop-base
docker run --name="hdp-03" --hostname=hdp-03 -it jp6907/hadoop-base
```

#### 4. 配置ip-域名映射
在每个容器中修改hosts文件
```
vim /etc/hosts

172.17.0.2      hdp-01
172.17.0.3      hdp-02
172.17.0.4      hdp-03
```
之后容器间就可以通过域名来相互访问了

#### 5. 启动HDFS程序
在namenode容器中，即hdp-01，初始化hdfs文件系统
```
hadoop namenode -format
```
一键启动/关闭所有namenode和datanode
```
start-dfs.sh
stop-dfs.sh
```
也可以单独启动当前主机的目标程序
```
hadoop-daemon.sh start namenode/datanode
```
之后可以查看已启动的程序
```
root@hdp-01:~# jps                 
1081 NameNode
1226 DataNode
1451 Jps
```
> 一键启动其实是使用ssh登录到其它机器去执行hadoop-daemon.sh脚本，所以必须配置容器间免密登录，在Dockerfile中已经配置


#### HDFS配置
- namenode为 hdp-01:9000
- namenode.secondary为 hdp-02:50090
- datanode为 hdp-01 hdp-02 hdp-03 （slaves）
- namenode dir为 /root/dfs/name
- datanode dir为 /root/dfs/data
- dfs.replication副本数量为 2

#### 关于端口
必须暴露的端口：
- ssh：22
- namenode：9000
- namenode.secondary：50090
- 查看文件系统：50070

#### 关于网络
docker run -net + 网络模式
在启动docker之后，如果不指定网络模式，则默认使用桥接模式          
在主机执行
```
ifconfig
```
可以看到，名为docker0的网络已经被建立，该网络的网关是172.17.0.0           
主机分配的ip地址为172.17.0.1，而所有被启动的docker容器都会分配一个172.17.0.X的ip地址
```
docker0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 0.0.0.0
        inet6 fe80::42:82ff:fe88:1145  prefixlen 64  scopeid 0x20<link>
        ether 02:42:82:88:11:45  txqueuelen 0  (Ethernet)
        RX packets 422425  bytes 26001130 (24.7 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 549452  bytes 955319587 (911.0 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```
接下来，可以配置ip-域名映射(集群中所有的逻辑主机都要配置，即所有容器)
```
vim /etc/hosts

172.17.0.1      hdp-00
172.17.0.3      hdp-02
172.17.0.2      hdp-01
```
为了能在主机上访问hadoop集群的HDFS文件系统，必须有一个容器的docker的50070端口被映射到主机的某个端口
如：
```
docker run --name="hdp-01" -p 8122:22 -p 50070:50070 -it jp6907/hadoop-base
```
之后，就可以就可以在浏览器直接访问：
```
localhost:50070
```
或者，在容器中暴露50070端口，通过ip+端口访问：
```
172.17.0.X:50070
```

