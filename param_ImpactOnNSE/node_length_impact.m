%% 在指定漫流宽度的情况下，主要扫描与部分管长选用，获得对NSE的影响程度
% '各Length参数下不同降雨的NSE值随Width变化的折线图'
% 更改降雨序列，根据文件名识别节点数，计算NSE变化规律
% SWMM_model_running输出一个2400 * 11的结果矩阵
% 上程序内置timeseries_file_generate(locG, rain, LOC_RAIN, newValue)

% mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次

%%  概化参数的起始点确认及输入
rain = [1,2,3,4,5,6,7,8,9,10,11];% 1a - rainfall
% nodesCount = [1,2,3,4,5,6,7,8]; % R的页数

% ###########################更改字段##############################
NAME = 'J17';
p = '1a';
nodesCount = [2,5,8,11,14,17]; % 长度 = R的页数，概化范围总支管范围
nodename1 = num2str(nodesCount(1));
nodename2 = num2str(nodesCount(end));
ave_length = 104.19;
C_width = 550.2;
outlet_height = 9.1;
% ###########################更改字段##############################

node_T = 127;
pngsave_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5.7-参数算法结果图';
%指定模拟时间(min)，图像横坐标
time = 40;
steps = 40 * 60;
node_T = 127;
slope = 0.005;
ground_height = 12.7;
pic_title = sprintf( '%s - Node %s - Node %s - %.2f - %.2f', NAME, nodename1, nodename2, ave_length, C_width)
% G-Model 文件路径
base_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\';
% ###########################更改字段##############################
file_template = 'UR_GModel_ds_3_%dnode_ver.inp'; % %d为节点数占位符
% file_template = 'UR_GModel_ds_1_%dnode_ver.inp'; % %d为节点数占位符
% file_template = 'UR_GModel_ms_2node_ver.inp'; % %d为节点数占位符
% file_template = 'UR_GModel_us_1node_ver.inp'; % %d为节点数占位符
% ###########################更改字段##############################
output_dir = fullfile(base_path);


% T-Model 文件路径
% 文件查找和运行

version_match = regexp(file_template, 'ds_(\d+)', 'tokens');
%version_match = regexp(file_template, 'ms', 'tokens');
%version_match = regexp(file_template, 'us', 'tokens');

if isempty(version_match)
    error('模板文件名格式错误，未找到ds_版本号');
end

ds_version = version_match{1}{1};  % 下游相关
%ds_version = version_match;  % 中上游相关

% 生成目标路径（自动继承版本号）
 new_filename = sprintf('UR_TModel_ds_%s', ds_version);  % 动态插入版本
% new_filename = sprintf('UR_TModel_ms', ds_version);  
%new_filename = sprintf('UR_TModel_us');  
output_path = fullfile(base_path, new_filename);

output_basicpath = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\7-运行结果储存\T-Model_result';
file_path = fullfile(output_basicpath, [new_filename, '_',p '_Results.mat']);
load(file_path);  % 加载后T-Model 运行结果 A_T 将直接可用，注意模型及重现期的对应
A_T;

% 管长初始网格划定
paramgap = 12; % 0.5为一个网格系数
lowmultiple = 0.5;
upmultiple = 4;
multipliers = linspace(lowmultiple, upmultiple, paramgap);
Length_Param = ave_length * multipliers;
Length_Param = round(Length_Param * 100) / 100; 

% 漫流宽度初始网格
paramgap = 5; % 后续参数指定部分
lowmultiple = 0.1;
upmultiple = 2;
multipliers = linspace(lowmultiple, upmultiple, paramgap);
Width_Param = C_width * multipliers;
Width_Param = round(Width_Param * 100) / 100; 

[N_gap, W_gap] = meshgrid(nodesCount, Length_Param);
param_combinations = [N_gap(:), W_gap(:)];
B_G = zeros(steps, length(rain), size(param_combinations,1));

% G_Model 文件遍历
for param_idx = 1:size(param_combinations,1)
    % 参数指定
    current_W = C_width;

    current_NC = param_combinations(param_idx, 1);
    % 生成动态文件路径
    current_file = fullfile(output_dir, sprintf(file_template, current_NC));
    locG = current_file;
    locG_temp = strrep(locG,'.inp','temp.inp');
    locG_temp_report = strrep(locG_temp,'temp.inp','temp.rpt');
    copyfile(locG,locG_temp); %此句之后的文件均用temp

    % 漫流宽度写入
    width_file_generate(locG_temp , 70, current_W);
    % 管长写入 
    current_TL = param_combinations(param_idx, 2);
    drain_file_generate(locG_temp , current_NC , 52 , 18, 29 , current_TL , outlet_height);
    % 模型运行
    B_G(:,:,param_idx) = SWMM_model_running(locG_temp ,locG_temp_report ,rain, current_NC);
end
R = NSE_calculation_3d_opticalvision(B_G, A_T);
%% 保存CSV.MAT文件
% pngsave_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5.7-参数算法结果图\节点网格寻优';
%output_basicpath = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\7-运行结果储存\node_net_results';
save_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5.7-参数算法结果图\param_impact';

% save_path = fullfile(output_basicpath, [NAME,'-',nodename, '-',p '_T_result_sorted.csv']);
% writetable(T_result_sorted, save_path);
% disp(['csv细化搜索结果已保存到: ' save_path]);
lengthname = num2str(ave_length);
widthname = num2str(C_width);
mat_path = fullfile(save_path, ['NSE-Node-length-', NAME,'-',nodename1, '-', nodename2, '-', lengthname,'-',widthname, '.mat']);
save(mat_path, 'R', 'param_combinations', 'Length_Param', 'Width_Param', 'nodesCount',...
    'B_G', 'rain', ...
    'A_T');
disp(['MAT文件已保存至: ' mat_path]);