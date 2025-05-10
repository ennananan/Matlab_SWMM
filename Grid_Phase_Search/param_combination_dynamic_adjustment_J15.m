%% 逐步网格搜索 + 动态范围调整的最佳参数组合范围研究-第4节点——J15
% 当前思路 依据起点统计结果与敏感性分析结果，从敏感性较大的width和length开始进行网格搜索和评价，后续再进行结果的更改；
% 计算原则，R可以求均值，流量不可

% SWMM_model_running输出一个2400 * 11的结果矩阵
% 上程序内置timeseries_file_generate(locG, rain, LOC_RAIN, newValue)

% 每次重新打开软件都要创建一次
% mex -setup;loadlibrary('swmm5');

%% 起点参数确认***注意模拟范围
rain = [1,2,3,4,5,6,7,8,9,10,11];% 1a - rainfall
p = '1a';
nodesCount = (4); % 长度 = R的页数，概化范围总支管范围
nodename = num2str(nodesCount);
ave_length = 111.4;
C_width = 2114.08;
node_T = 127;
pngsave_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5.7-参数算法结果图';
output_basicpath = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\7-运行结果储存';
%指定模拟时间(min)，图像横坐标
time = 40;
steps = 40 * 60;

% 管长初始网格划定
paramgap = 7; % 0.5为一个网格系数
lowmultiple = 0.5;
upmultiple = 3.5;
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

% 文件路径

% G-Model 文件路径
base_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\';
file_template = 'UR_GModel_ds_2_%dnode_ver.inp'; % %d为节点数占位符
output_dir = fullfile(base_path);

% T-Model数据读取
% 文件查找和运行
version_match = regexp(file_template, 'ds_(\d+)', 'tokens');
ds_version = version_match{1}{1};  % 提取到'3'——面积节点提取

% 生成目标路径（自动继承版本号）使用TModel_flow_resultsaving.m提前生成相关算法
new_filename = sprintf('UR_TModel_ds_%s', ds_version);  % 动态插入版本号
file_path = fullfile(output_basicpath, [new_filename, '_',p '_Results.mat']);
load(file_path);  % 加载后T-Model 运行结果 A_T 将直接可用，注意模型及重现期的对应
% A_T
%% 初始网格计算

% G_Model文件遍历

% 生成网格坐标矩阵
[L_grid, W_grid] = meshgrid(Length_Param, Width_Param);
% 组合成参数对矩阵 (N×2矩阵)
param_combinations = [L_grid(:), W_grid(:)];
B_G = zeros(steps, length(rain), size(param_combinations,2));
R = zeros(size(param_combinations,1), size(rain,2), size(nodesCount,2));

for node_idx  = 1: size(nodesCount,2)

    % 参数指定
    current_NC = nodesCount(:,node_idx);

    for param_idx = 1:size(param_combinations,1)
        % 生成动态文件路径
        current_file = fullfile(output_dir, sprintf(file_template, current_NC));

        locG = current_file;
        locG_temp = strrep(locG,'.inp','temp.inp');
        locG_temp_report = strrep(locG_temp,'temp.inp','temp.rpt');
        copyfile(locG,locG_temp); %此句之后的文件均用temp

        current_W = param_combinations(param_idx,2);  
        %current_W = 2114;
        % 漫流宽度写入
        sectionLine=findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
        width_file_generate(locG_temp ,locG_temp , sectionLine ,current_W );

        current_TL = param_combinations(param_idx,1);
        % 管道参数修改
        % drain_file_generate(locG , node , LOC_CONDUITS , LOC_JUNCTIONS_1st, LOC_JUNCTIONS_2nd , G_Length , G_Height)
        % J17 = 9.1; J15 = 9.65
        drain_file_generate(locG_temp , current_NC , 52 , 18, 29 , current_TL , 9.65);

        % 运行模型
        % SWMM_model_running(inputfile, report_file, rain, current_NC) 
        %                    输入文件， 运行需要， 降雨数量，节点指定
        B_G(:,:,param_idx) = SWMM_model_running(locG_temp ,locG_temp_report ,rain, current_NC);
        % B_G = (steps ,length(rain) ,param_num) = (2400, 11, NC)     
    end

%% 求NSE
R(:,:,node_idx) = NSE_calculation_3d_opticalvision(B_G, A_T);
% 数据结构描述：管长 * 降雨 * 节点数
% 注意输入矩阵的规模匹配
end
R;

%% 识别Top-3最优参数组合
top_k = 5;
threshold_width_diff = 80;  % 宽度差异容忍（单位m）
threshold_length_diff = 20;  % 管长差异容忍（单位m）

R_col_means = mean(R, 2); % 一个列向量
[sorted_vals, sorted_idx] = sort(R_col_means(:), 'descend');
top_indices = sorted_idx(1:top_k);
% top_params = param_combinations(top_indices, :); % 每行是一个 [Length, Width]

% 有差异的参数组合选择

top_params = []; % 最优参数存储
selected_widths = [];
selected_lengths = [];

i = 1; % 排序索引
while size(top_params,1) < top_k && i <= length(sorted_idx)
    candidate_idx = sorted_idx(i);
    candidate_param = param_combinations(candidate_idx, :); % [Length, Width]

    % 检查当前width和length是否都与已有选择不接近
    width_ok = isempty(selected_widths) || all(abs(candidate_param(2) - selected_widths) > threshold_width_diff);
    length_ok = isempty(selected_lengths) || all(abs(candidate_param(1) - selected_lengths) > threshold_length_diff);

    if width_ok && length_ok
        top_params = [top_params; candidate_param];
        selected_widths = [selected_widths; candidate_param(2)];
        selected_lengths = [selected_lengths; candidate_param(1)];
    end
    i = i + 1;
end

%% 局部细化搜索参数 
fine_gap = 20; % 局部细化步数
expand_ratio = 0.5; % 对局部区域扩展 ±百分比
R_fine_all = [];

% 初始化同步记录
Length_all = [];
Width_all = [];
NSE_all = [];
PE_all = [];
SOD_all = [];
PTE_all = [];

R_fine = zeros(fine_gap ^ 2 , size(rain,2));
Peak_Error_matrix = zeros(fine_gap ^ 2 , top_k);
PTE_matrix = zeros(fine_gap ^ 2, top_k);
SOD_matrix = zeros(fine_gap ^ 2, top_k);

sectionLine=findInpSectionLine(locG_temp, 'SUBCATCHMENTS');

for parm_idx = 1:top_k
    center_length = top_params(parm_idx, 1);
    center_width = top_params(parm_idx, 2);

    % 定义局部初始范围（±expand_ratio）
    length_range = linspace(center_length * (1 - expand_ratio), ...
                            center_length * (1 + expand_ratio), fine_gap);
    width_range  = linspace(center_width  * (1 - expand_ratio), ...
                            center_width  * (1 + expand_ratio), fine_gap);

    [L_fine, W_fine] = meshgrid(length_range, width_range);
    fine_combinations = [L_fine(:), W_fine(:)]; % fine_gap * fine_gap, 2

   
    B_G_fine_param = zeros(steps, length(rain), size(fine_combinations,1));
    R_fine = zeros(size(fine_combinations,1), length(rain), top_k); % 局部NSE单独存
    PE_temp_all = zeros(size(fine_combinations,1), length(rain));
    SOD_temp_all = zeros(size(fine_combinations,1), length(rain));
    PTE_temp_all = zeros(size(fine_combinations,1), length(rain));

    for fine_param_idx = 1:size(fine_combinations,1)

        current_TL = fine_combinations(fine_param_idx, 1);
        current_W = fine_combinations(fine_param_idx, 2);

        % 写入新参数
        width_file_generate(locG_temp ,locG_temp , sectionLine ,current_W );
        drain_file_generate(locG_temp , current_NC , 52 , 18, 29 , current_TL , 9.1);

        % 运行模型
        B_G_fine_param(:,:,fine_param_idx) = SWMM_model_running(locG_temp ,locG_temp_report ,rain, current_NC);
        
        % 新增的评价指标计算, 均值化不可行, 对每一场降雨进行计算后单独分析
        for rain_idx = 1:length(rain)
            Q_sim = B_G_fine_param(:, rain_idx, fine_param_idx); % 当前场模拟
            Q_obs = A_T(:, rain_idx);                      % 当前场观测

            [pe, pte, sod] = additional_metrics(Q_sim, Q_obs, 1);

            PE_temp_all(fine_param_idx, rain_idx)  = pe;
            PTE_temp_all(fine_param_idx, rain_idx) = pte;
            SOD_temp_all(fine_param_idx, rain_idx) = sod;
        end

    end

    % 计算这一组参数在所有降雨下的指标平均值
    Peak_Error_matrix(:, parm_idx)  = mean(PE_temp_all,2);
    PTE_matrix(:, parm_idx) = mean(PTE_temp_all,2);
    SOD_matrix(:, parm_idx) = mean(SOD_temp_all,2);

    % 计算局部NSE
    R_fine(:, :, parm_idx) = NSE_calculation_3d_opticalvision(B_G_fine_param, A_T);
    
    
    % 计算平均NSE，边界判断
    R_temp_mean = mean(R_fine(:,:,parm_idx), 2);

    % 以列向扩展的方式将参数和结果拼在了一个矩阵里以供选择
    R_fine_all = [R_fine_all; fine_combinations, R_temp_mean]; % 对应参数NSE页每行求均值，均值化了降雨事件

    % 将每组局部细化搜索结果累积到总数组（每一行是一个组合）
    Length_all = [Length_all; fine_combinations(:,1)];
    Width_all  = [Width_all; fine_combinations(:,2)];
    PE_all  = [PE_all;  fine_combinations, Peak_Error_matrix(:, parm_idx)];
    PTE_all = [PTE_all; fine_combinations, PTE_matrix(:, parm_idx)];
    SOD_all = [SOD_all; fine_combinations, SOD_matrix(:, parm_idx)];
    NSE_all = R_fine_all;
end

 % PE、PTE、SOD拉平成一列（注意顺序），G老师说有问题，还要再看
 Length_vector = Length_all;
 Width_vector =  Width_all;
 NSE_vector = NSE_all(:,3);
 PE_vector  = PE_all(:,3);
 PTE_vector = PTE_all(:,3);
 SOD_vector = SOD_all(:,3);

 %% 综合得分计算
% 推荐加权参数（可以调整）
w_NSE = 0.6;  % NSE权重
w_PE  = 0.3;  % 峰值误差权重
w_SOD = 0.1;  % 流量稳定性权重

% 归一化（防止不同指标量纲不一致）
 NSE_norm = (NSE_vector - min(NSE_vector)) / (max(NSE_vector) - min(NSE_vector));
 PE_norm  = (1 - abs(PE_vector)) ./ (1 + abs(PE_vector)); % 越小越好
 SOD_norm = (1 - abs(SOD_vector)) ./ (1 + abs(SOD_vector)); % 越小越好

% 计算最终综合得分
score = w_NSE * NSE_norm + w_PE * PE_norm + w_SOD * SOD_norm;

%% 整理成表格并排序
T_result = table(Length_vector, Width_vector, NSE_vector, PE_vector, SOD_vector, score, ...
    'VariableNames', {'Length', 'Width', 'NSE', 'PE', 'SOD', 'Score'});

% 按score降序排列
T_result_sorted = sortrows(T_result, 'Score', 'descend')

%% 保存CSV.MAT文件
save_path = fullfile(output_basicpath, ['J15-',nodename, '-',p '_T_result_sorted.csv']);
writetable(T_result_sorted, save_path);
disp(['csv细化搜索结果已保存到: ' save_path]);

mat_path = fullfile(output_basicpath, ['J15-',nodename, '-',p '_T_result_sorted.mat']);
save(mat_path, 'T_result_sorted', 'rain', 'nodesCount','p','nodename', ...
    'ave_length', 'C_width','Length_all','Width_all','score', ...
    'fine_gap', 'expand_ratio');
disp(['MAT文件已保存至: ' mat_path]);

%% 绘制参数搜索热力图（Length vs Width）
figure;
scatter(Length_all, Width_all, 40, score, 'filled');
colorbar;
xlabel('Length');
ylabel('Width');
title('局部细化搜索结果热力图');
colormap(turbo); % 颜色映射
grid on;
set(gca, 'FontSize', 12);