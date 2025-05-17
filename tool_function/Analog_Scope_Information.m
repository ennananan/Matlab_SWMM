% 模型信息修改保存
%第一节点
NAME = 'J5';
p = '1a';
nodesCount = (1); % 长度 = R的页数，概化范围总支管范围
nodename = num2str(nodesCount);
ave_length = 76.25;
C_width = 434;
outlet_height = 11.25;

file_template = 'UR_GModel_us_1node_ver.inp'; % %d为节点数占位符

version_match = regexp(file_template, 'us_(\d+)', 'tokens');

new_filename = sprintf('UR_TModel_us', ds_version); 

%第二节点
NAME = 'J10';
p = '1a';
nodesCount = (2); % 长度 = R的页数，概化范围总支管范围
nodename = num2str(nodesCount);
ave_length = 97.07;
C_width = 1192.46;
outlet_height = 10.55;

file_template = 'UR_GModel_ms_2node_ver.inp'; % %d为节点数占位符

version_match = regexp(file_template, 'ms_(\d+)', 'tokens');

new_filename = sprintf('UR_TModel_ms', ds_version);

%第三节点
NAME = 'J11';
p = '1a';
nodesCount = (3); % 长度 = R的页数，概化范围总支管范围
nodename = num2str(nodesCount);
ave_length = 93.18;
C_width = 1448.09;
outlet_height = 10.33;

file_template = 'UR_GModel_ds_1_%dnode_ver.inp'; % %d为节点数占位符

version_match = regexp(file_template, 'ds_(\d+)', 'tokens');

new_filename = sprintf('UR_TModel_ds_%s', ds_version);  % 动态插入版本号

%第四节点
NAME = 'J15';
p = '1a';
nodesCount = (4); % 长度 = R的页数，概化范围总支管范围
nodename = num2str(nodesCount);
ave_length = 111.4;
C_width = 2114.08;
outlet_height = 9.7;

file_template = 'UR_GModel_ds_2_%dnode_ver.inp'; % %d为节点数占位符

version_match = regexp(file_template, 'ds_(\d+)', 'tokens');

new_filename = sprintf('UR_TModel_ds_%s', ds_version);  % 动态插入版本号

%第五节点
NAME = 'J17';
p = '1a';
nodesCount = (5); % 长度 = R的页数，概化范围总支管范围
nodename = num2str(nodesCount);
ave_length = 104.19;
C_width = 2334.37;
outlet_height = 9.1;

file_template = 'UR_GModel_ds_3_%dnode_ver.inp'; % %d为节点数占位符

version_match = regexp(file_template, 'ds_(\d+)', 'tokens');

new_filename = sprintf('UR_TModel_ds_%s', ds_version);  % 动态插入版本号