FROM ubuntu:14.04
MAINTAINER zjp

USER root

#install tools
RUN apt-get update -y
RUN apt-get install -y openssh-server curl tar vim

# 复制java、hadoop安装包、hadoop配置文件
# ADD复制进容器会自动解压
ADD config/jdk-8u201-linux-x64.tar.gz /  
ADD config/hadoop-2.8.1.tar.gz /
RUN mv /jdk1.8.0_201/ /usr/local/jdk && \
    mv /hadoop-2.8.1 /usr/local/hadoop 
ADD config/hadoop-config/*  /usr/local/hadoop/etc/hadoop/

# ENV JAVA_HOME /usr/local/jdk
# ENV PATH $PATH:$JAVA_HOME/bin

# ENV HADOOP_HOME /usr/local/hadoop
# ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# 设置环境变量、创建hadoop工作目录
RUN sed -i '$a export JAVA_HOME=/usr/local/jdk\nexport PATH=$PATH:$JAVA_HOME/bin\n' /etc/profile && \
    sed -i '$a export HADOOP_HOME=/usr/local/hadoop\nPATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin\n' /etc/profile && \
    mkdir -p /root/dfs/name && \
    mkdir -p /root/dfs/data

# ssh免密登录
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    mkdir /var/run/sshd

CMD [ "sh", "-c", "service ssh start; bash"]

EXPOSE 22 9000 50070 8088 50090

