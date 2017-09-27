执行办法：
1.    先确保有节点间的tidb用户可以相互无口令ssh登录,或者可以使用  ssh -i key 的方式登录. 如果使用 key 登录，请先配置环境变量
export sshauth="-i /home/tidb/.ssh/idckey"
2.    把本包复制到所有的节点上，并解压到相同的路径。例如：/tmp/diagnostics
3.    修改clusterdiag.sh中的NODE_LIST，保证所有的节点主机名或IP都在内表中；或者设置环境变量: export NODE_LIST="v001 v002 v003 …"
如果使用 idckey 作为 ssh 登录要求，请在 vnetperf 命令参数中增加 --identity-file idckey 
4.    确保数据存储空间mount到/data 上。否则修改diagnostics.sh的第3行DATA_DIR="/data"
5.    在其中一个节点上执行clusterdiag.sh

clusterdiag.sh: 诊断和收集集群配置的工具
    诊断：收集集群内所有节点的配置信息，测试CPU（通过 vcpuperf ）磁盘（通过Vertica自己的I/O模型工具 vioperf）和网络带宽（通过 vnetperf）
    诊断结果在： clusterdiag-`date +%Y%m%d%H%M%S`.log   （取开始执行的时间）。在结果中：
        搜索“vcpuperf”，能找到CPU的计算能力，以及是否存在scaling
        搜索“Network bandwidth test”，能找到节点之间的TCP/UDP带宽
        搜索“vioperf”，能找到磁盘读写能力

getconfigs.sh: 收集服务器配置的工具
    结果在：configs-`date +%Y%m%d%H%M%S`.tgz （取开始执行的时间）
