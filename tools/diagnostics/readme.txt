
ִ�а취��
1.	��ȷ���нڵ���root�û������໥�޿���ssh��¼
2.	�ѱ������Ƶ����еĽڵ��ϣ�����ѹ����ͬ��·�������磺/root/diagnostics
3.	�޸�clusterdiag.sh�е�NODE_LIST����֤���еĽڵ���������IP�����ڱ��У��������û�������: export NODE_LIST="v001 v002 v003 ��"
4.	ȷ�����ݴ洢�ռ�mount��/data �ϡ������޸�diagnostics.sh�ĵ�3��DATA_DIR="/data"
5.	������һ���ڵ���ִ��clusterdiag.sh

clusterdiag.sh: ��Ϻ��ռ���Ⱥ���õĹ���
	��ϣ��ռ���Ⱥ�����нڵ��������Ϣ������CPU��ͨ�� vcpuperf �����̣�ͨ��Vertica�Լ���I/Oģ�͹��� vioperf�����������ͨ�� vnetperf��
	��Ͻ���ڣ� clusterdiag-`date +%Y%m%d%H%M%S`.log   ��ȡ��ʼִ�е�ʱ�䣩���ڽ���У�
		������vcpuperf�������ҵ�CPU�ļ����������Լ��Ƿ����scaling
		������Network bandwidth test�������ҵ��ڵ�֮���TCP/UDP����
		������vioperf�������ҵ����̶�д����


getconfigs.sh: �ռ����������õĹ���
	����ڣ�configs-`date +%Y%m%d%H%M%S`.tgz ��ȡ��ʼִ�е�ʱ�䣩
