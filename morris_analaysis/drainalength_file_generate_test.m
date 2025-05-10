function drainalength_file_generate_test

%在固定节点数量前提下，对管长和标高更改文件进行生成，命名和位置指定

%OUTFALLS-出口标高，与目标概化区域的末端节点标高一致，在初始建模时设定、
%JUNCTIONS-节点标高设置，目标地面，标高12.7
%CONDUITS-管道长度设置

%do_plot = false; 
%if do_plot %设置开关，不执行绘图代码

%mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次

%概化模型—G-Model
locG='C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_GModel_ds_3_2node_ver.inp';

%模型文件格式整理
locG_temp=strrep(locG,'.inp','temp.inp');
locG_temp_report=strrep(locG_temp,'temp.inp','temp.rpt');
copyfile(locG,locG_temp); 

%======基础表格统计结果设置========
node = 2;             %模型节点数量
LOC_CONDUITS = 52;               %文件位置阅读保存
LOC_JUNCTIONS_1st = 18;
LOC_JUNCTIONS_2nd = 29;
%G_Length = 350.056;  %--孪生模型统计结果
G_Length = 200; 

G_Height = 9.1;      %起始高度为OUTFALL的高度
slope = 0.005;
ground = 12.7;
%gap=20;             %--数据gap设置
%lowmultiple=0.1;    %倍数下界
%upmultiple=3.5;     %倍数上界
%multipliers=linspace(lowmultiple,upmultiple,gap);
%===================================
%G-Model

%【CONDUITS】       
%G_length_Param=G_Length*multipliers;
G_length_Param = ones(1, node) * ( G_Length / node ) ;
G_length_Param = round( G_length_Param *10000 ) / 10000;

% CONDUITS 管长写入
sectionLine = findInpSectionLine(locG_temp , 'CONDUITS');
replaceInpValue_write_in(locG_temp ,locG_temp ,sectionLine ,node ,LOC_CONDUITS , G_length_Param);

%【JUNCTIONS】节点标高储存和选用

G_dheight = (G_Length / node) * slope ;   %高度差
ground_height = ones(node,2) ;      %第一列 - 节点标高 ；第二列 - 地面标高
for i = 1: node
    node_elev = G_Height + i * G_dheight ;
    ground_elev = ground - node_elev ;
    ground_height(i, :) = [...
            round(node_elev * 100)/100, ...
            round(ground_elev * 100)/100 ...
            ];
end


% JUNCTIONS 节点标高写入
sectionLine = findInpSectionLine( locG_temp , 'JUNCTIONS' );
replaceInpValue_write_in( locG_temp ,locG_temp ,sectionLine ,node ,LOC_JUNCTIONS_1st , ground_height(:,1)' );
replaceInpValue_write_in( locG_temp ,locG_temp ,sectionLine ,node ,LOC_JUNCTIONS_2nd , ground_height(:,2)' );
end
