clear all
%% 文件load

%length = T_result_sorted{2:end,1};

%save(mat_path, 'T_result_sorted', 'rain', 'nodesCount','p', ...
%    'ave_length', 'C_width','Length_all','Width_all','score', ...
%    'fine_gap', 'expand_ratio');
file_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\7-运行结果储存\J15-t4-1a_T_result_sorted.mat';
load(file_path);  
selected_data = T_result_sorted{:, {'Length', 'Width','NSE','Score','PE','SOD'}}; % 通过列名

rain = [1,2,3,4,5,6,7,8,9,10,11];% 1a - rainfall
p = '1a';
nodesCount = (4); % 长度 = R的页数，概化范围总支管范围
nodename = num2str(nodesCount);
ave_length = 104.2;
C_width = 2334.37;
node_T = 127;
pngsave_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5.7-参数算法结果图';
output_basicpath = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\7-运行结果储存';
%指定模拟时间(min)，图像横坐标
time = 40;
steps = 40 * 60;

% G-Model 文件路径
base_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\';

% 固定更改位置指明文件
file_template = 'UR_GModel_ds_2_%dnode_ver.inp'; % %d为节点数占位符
output_dir = fullfile(base_path);

% T-Model数据读取
% 文件查找和运行
version_match = regexp(file_template, 'ds_(\d+)', 'tokens');
ds_version = version_match{1}{1};  % 提取到'3'

% 生成目标路径（自动继承版本号）
new_filename = sprintf('UR_TModel_ds_%s', ds_version);  % 动态插入版本号
file_path = fullfile(output_basicpath, [new_filename, '_',p '_Results.mat']);
load(file_path);  % 加载后T-Model 运行结果 A_T 将直接可用，注意模型及重现期的对应
% A_T


%% 边界细化判断
    % 文件数据重排列
    %NSEalll = reshape(T_result_sorted{:, {'NSE'}}, 20, 20, 5); % 通过列名,排过序的索引不是对应的
    N = size(selected_data,1);
    length_sorted = selected_data(:,1);
    width_sorted = selected_data(:,2);
    NSE = selected_data(:,3);
    Score = selected_data(:,4);
    NSE_reordered = zeros(N, 1); % 预分配
    Score_reorderd = zeros(N, 1);
    expand_param = [];
    for i = 1:N
        % 找到在 length_sorted 和 width_sorted 中匹配的位置
        idx = find(length_sorted == Length_all(i) & width_sorted == Width_all(i));
    
        if isempty(idx)
        error('找不到对应的参数组合。');
        end
    
        NSE_reordered(i) = NSE(idx);
        Score_reorderd(i) = Score(idx);
    end
% 初始数据指定
    top_k = 5;
    NSE_threshold = 0.95;
    Score_threshold = 0.79;

    NSE = reshape(NSE_reordered, fine_gap, fine_gap, top_k);
    Score = reshape(Score_reorderd, fine_gap, fine_gap, top_k);
    length_all = reshape(Length_all, fine_gap, fine_gap, top_k);
    width_all = reshape(Width_all, fine_gap, fine_gap, top_k);

    right_expand_param = [];
    expand_param_curr = [];
%矩阵初始化
    new_length = zeros(top_k, 1);
    new_width = zeros(top_k, 1);

for k = 1:top_k
     
    NSE_page = NSE(:, :, k);
    score_page = Score(:, :, k); 
    length_page = length_all(:, :, k);
    width_page = width_all(:, :, k);

    expand_param_curr = [];

    % 阈值判断掩码
    high_score_mask = score_page >= Score_threshold;
    highNSE_mask = NSE_page >= NSE_threshold;

    % 每页的边界掩码：第一行、最后一行、第一列、最后一列为 true
    boundary_mask = false(fine_gap, fine_gap);
    boundary_mask(1, :) = true;
    boundary_mask(end, :) = true;
    boundary_mask(:, 1) = true;
    boundary_mask(:, end) = true;

    % 同时满足高NSE和边界位置
    boundary_highNSE = highNSE_mask & boundary_mask; %NSE边界判断
    boundary_highScore = high_score_mask & boundary_mask;%Score边界判断

    %% 显示或输出信息，判断因素选择—NSE

    [row, col] = find(boundary_highNSE & boundary_highScore);

    if ~isempty(row)
        fprintf('第 %d 页有 %d 个 位于边界且 NSE≥0.95 & Score ≥ 0.78 的点：\n', k, size(row, 1));
        sum_length = zeros(size(row,1), 1);
        sum_width =  zeros(size(row,1), 1);
        for m = 1:size(row,1)
            fprintf('  位置 (%d, %d) - Length = %.2f, Width = %.2f, NSE = %.4f, Score = %.4f\n', ...
                row(m), col(m), ...
                length_all(row(m), col(m), k), ...
                width_all(row(m), col(m), k), ...
                NSE_page(row(m), col(m)), ...
                score_page(row(m), col(m)));

                expand_param= [expand_param; length_all(row(m), col(m), k),... 
                                width_all(row(m), col(m), k), NSE_page(row(m), col(m)), score_page(row(m), col(m))];
                sum_length(m,1) =length_all(row(m), col(m), k);
                sum_width(m,1) = width_all(row(m), col(m), k);
        end
        new_length(k, :) = mean(sum_length);
        new_width(k, :) = mean(sum_width);
    else
        fprintf('第 %d 页没有位于边界且 NSE≥0.95 & Score ≥ 0.78 的点。\n', k);
    end  

end



%% 边界扩展计算

new_length_cleaned = new_length(any(new_length, 2), :);
new_width_cleaned = new_width(any(new_width, 2), :);

param_secst = [new_length_cleaned, new_width_cleaned];

gap_secst = 15;  % 局部细化步数
expand_ratio = 0.5; % 对局部区域扩展 ±百分比
R_secst_all = [];

% 初始化同步记录
Length_all = [];
Width_all = [];
NSE_all = [];
PE_all = [];
SOD_all = [];
PTE_all = [];

for parm_idx = 1: size(new_length_cleaned,1)

    fprintf('第 %d 个判断点计算运行中...\n', parm_idx);

    center_length = param_secst(parm_idx, 1);
    center_width = param_secst(parm_idx, 2);
    % 定义局部初始范围（±expand_ratio）
    length_range = linspace(center_length * (1 - expand_ratio), ...
                            center_length * (1 + expand_ratio), gap_secst);
    width_range  = linspace(center_width  * (1 - expand_ratio), ...
                            center_width  * (1 + expand_ratio), gap_secst);

    [L_secst, W_secst] = meshgrid(length_range, width_range);
    secst_combinations = [L_secst(:), W_secst(:)]; % gap_secst * gap_secst, 2

    B_G_secst_param = zeros(steps, length(rain), size(secst_combinations,1));
    R_secst = zeros(size(secst_combinations,1), length(rain), top_k); % 局部NSE单独存
    PE_temp_all = zeros(size(secst_combinations,1), length(rain));
    SOD_temp_all = zeros(size(secst_combinations,1), length(rain));
    PTE_temp_all = zeros(size(secst_combinations,1), length(rain));

    for secst_param_idx = 1:size(secst_combinations,1)
        
        current_NC = nodesCount; % 此为单节点指定
        current_file = fullfile(output_dir, sprintf(file_template, current_NC));
        locG = current_file;
        locG_temp = strrep(locG,'.inp','temp.inp');
        locG_temp_report = strrep(locG_temp,'temp.inp','temp.rpt');
        copyfile(locG,locG_temp); %此句之后的文件均用temp

        current_TL = secst_combinations(secst_param_idx, 1);
        current_W = secst_combinations(secst_param_idx, 2);

        sectionLine=findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
        % 写入新参数
        width_file_generate(locG_temp ,locG_temp , sectionLine ,current_W );
        drain_file_generate(locG_temp , current_NC , 52 , 18, 29 , current_TL , 9.1);

        % 运行模型
        B_G_secst_param(:,:,secst_param_idx) = SWMM_model_running(locG_temp ,locG_temp_report ,rain, current_NC);
        
        % 新增的评价指标计算, 均值化不可行, 对每一场降雨进行计算后单独分析
        for rain_idx = 1:length(rain)
            Q_sim = B_G_secst_param(:, rain_idx, secst_param_idx); % 当前场模拟
            Q_obs = A_T(:, rain_idx);                      % 当前场观测

            [pe, pte, sod] = additional_metrics(Q_sim, Q_obs, 1);

            PE_temp_all(secst_param_idx, rain_idx)  = pe;
            PTE_temp_all(secst_param_idx, rain_idx) = pte;
            SOD_temp_all(secst_param_idx, rain_idx) = sod;
        end

    end

    % 计算这一组参数在所有降雨下的指标平均值
    Peak_Error_matrix(:, parm_idx)  = mean(PE_temp_all,2);
    PTE_matrix(:, parm_idx) = mean(PTE_temp_all,2);
    SOD_matrix(:, parm_idx) = mean(SOD_temp_all,2);

    % 计算局部NSE
    R_secst(:, :, parm_idx) = NSE_calculation_3d_opticalvision(B_G_secst_param, A_T);
    
    
    % 计算平均NSE，边界判断
    R_temp_mean = mean(R_secst(:,:,parm_idx), 2);

    % 以列向扩展的方式将参数和结果拼在了一个矩阵里以供选择
    R_secst_all = [R_secst_all; secst_combinations, R_temp_mean]; % 对应参数NSE页每行求均值，均值化了降雨事件

    % 将每组局部细化搜索结果累积到总数组（每一行是一个组合）

    Length_all = [Length_all; secst_combinations(:,1)];
    Width_all  = [Width_all; secst_combinations(:,2)];
    PE_all  = [PE_all;  secst_combinations, Peak_Error_matrix(:, parm_idx)];
    PTE_all = [PTE_all; secst_combinations, PTE_matrix(:, parm_idx)];
    SOD_all = [SOD_all; secst_combinations, SOD_matrix(:, parm_idx)];
    NSE_all = R_secst_all;
end
 % PE、PTE、SOD拉平成一列（注意顺序），G老师说有问题，还要再看


 %% 综合得分计算
% 推荐加权参数（可以调整）
w_NSE = 0.6;  % NSE权重
w_PE  = 0.3;  % 峰值误差权重
w_SOD = 0.1;  % 流量稳定性权重

% 归一化（防止不同指标量纲不一致）||score在两阶段需要重新拼接后统一计算，否则归一化过程中会产生两阶段计算不一致的情况
 Length_vector = [selected_data(:, 1); Length_all];
 Width_vector = [selected_data(:, 2); Width_all];
 NSE_vector = [selected_data(:, 3); NSE_all(:,3)];
 PE_vector  = [selected_data(:, 5); PE_all(:,3)];
 PTE_vector = PTE_all(:,3);
 SOD_vector = [selected_data(:, 6); SOD_all(:,3)];

 NSE_norm_secst = (NSE_vector - min(NSE_vector)) / (max(NSE_vector) - min(NSE_vector));
 PE_norm_secst  = (1 - abs(PE_vector)) ./ (1 + abs(PE_vector)); % 越小越好
 SOD_norm_secst = (1 - abs(SOD_vector)) ./ (1 + abs(SOD_vector)); % 越小越好

% 计算最终综合得分//
score_secst = w_NSE * NSE_norm_secst + w_PE * PE_norm_secst + w_SOD * SOD_norm_secst;

%% 整理成表格并排序
T_result_secst = table(Length_vector, Width_vector, NSE_vector, PE_vector, SOD_vector, score_secst, ...
    'VariableNames', {'Length', 'Width', 'NSE', 'PE', 'SOD', 'Score'});

% 按score降序排列
T_result_secst = sortrows(T_result_secst, 'Score', 'descend');

selected_combined_data = T_result_secst{:, {'Length', 'Width','NSE','Score'}}; % 通过列名

Length_all_combined = selected_combined_data(:, 1);
Width_all_combined = selected_combined_data(:, 2);
NSE_combined = selected_combined_data(:, 3);
score_combined = selected_combined_data(:, 4);



%% 保存CSV.MAT文件
save_path = fullfile(output_basicpath, ['J15-',nodename, '-',p '_T_result_sorted.csv']);
writetable(T_result_sorted, save_path);
disp(['csv细化搜索结果已保存到: ' save_path]);

mat_path = fullfile(output_basicpath, ['J15-',nodename, '-',p '_T_result_sorted.mat']);
save(mat_path, 'T_result_sorted', 'rain', 'nodesCount','p', ...
    'ave_length', 'C_width','Length_all_combined','Width_all_combined','score_secst', ...
    'gap_secst', 'expand_ratio', 'NSE_all','NSE_combined','score_combined');
disp(['MAT文件已保存至: ' mat_path]);

%% 绘制参数搜索热力图（Length vs Width）
% 横纵坐标处理

figure;

scatter(Length_all_combined, Width_all_combined, 40, score_combined, 'filled');
colorbar;
xlabel('Length');
ylabel('Width');
title('局部细化搜索结果热力图');
colormap(turbo); % 颜色映射
clim([0.4 0.85]);            % 可集中在高分区间
grid on;
set(gca, 'FontSize', 12);
