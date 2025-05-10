%% Morris敏感性分析完整流程
% 适用场景：含整数和连续参数的工程模型敏感性分析
% 判断三类参数对全过程NSE和峰值NSE的敏感程度

% mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次

%% 步骤1：定义参数范围和属性
param_def = {
    'TotalLength',   'continuous', [50, 350];    % 总管长（连续型）
    'NodeCount',     'integer',    [1, 6];       % 节点数（整数型）
    'Width',         'continuous', [200, 2500]   % 漫流宽度（连续型）
};
format short;
% 参数有效性检查函数
check_validity = @(x) x(1)/(x(2)+1) >= 10; % 单管长≥10m约束
%param_def{:,3}(1
%轨迹数量
orbit = 100;

%% 步骤2：生成Morris轨迹样本
% 生成轨迹

[traj, delta] = generate_morris_trajectories(param_def, orbit);
length(traj);
%traj

%% 步骤3：样本参数写入
% 定义基础文件路径模板
rain = [1,2,3,4,5,6,7,8,9,10,11]; % 1a-rainfall
steps = 40 * 60;

% G-Model 文件路径
base_path = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\';
file_template = 'UR_GModel_ds_3_%dnode_ver.inp'; % %d为节点数占位符
output_dir = fullfile(base_path);
param_num = size(traj,1);
B_G = zeros(steps, length(rain));

% T-Model
% 文件查找和运行
version_match = regexp(file_template, 'ds_(\d+)', 'tokens');
if isempty(version_match)
    error('模板文件名格式错误，未找到ds_版本号');
end
ds_version = version_match{1}{1};  % 提取到'3'

% 生成目标路径（自动继承版本号）
new_filename = sprintf('UR_TModel_ds_%s.inp', ds_version);  % 动态插入版本号
output_path = fullfile(base_path, new_filename);
% current_file1 = fullfile(output_dir, sprintf(file_template, current_NC));

%T-Model 具体操作
node_T = 127;

locT = output_path;
locT_temp = strrep(locT, '.inp', 'temp.inp');
locT_temp_report = strrep(locT_temp, 'temp.inp', 'temp.rpt');
copyfile(locT, locT_temp);

for rain_num = 1:length(rain)
    
    % timeseries_file_generate(locG, rain, LOC_RAIN, newValue)
     %timeseries_file_generate(locT_temp, rain, 59, rain_num)
    % SWMM_model_running(inputfile, report_file, rain, param_num, param_index, current_NC)
     A_T = SWMM_model_running(locT_temp ,locT_temp_report ,rain, node_T);
     % A = (steps ,length(rain) ,param_num) = (2400, 11, 1)
end
A_T;
size(A_T);

% G-Model Morris轨迹遍历所有样本
for i = 1:size(traj,1)

    % 提取当前样本参数
    current_TL = traj(i,1);   % 总管长
    current_NC = round(traj(i,2)); % 节点数(确保整数)
    current_W = traj(i,3);    % 漫流宽度

     % 生成动态文件路径
    current_file = fullfile(output_dir, sprintf(file_template, current_NC));
    locG = current_file;
    locG_temp = strrep(locG,'.inp','temp.inp');
    locG_temp_report = strrep(locG_temp,'temp.inp','temp.rpt');
    copyfile(locG,locG_temp); 

    % 漫流宽度写入
    sectionLine=findInpSectionLine(locG_temp, 'SUBCATCHMENTS');
    width_file_generate(locG_temp ,locG_temp , sectionLine ,current_W );
    % 管道数据写入
    % drain_file_generate(locG , node , LOC_CONDUITS , LOC_JUNCTIONS_1st, LOC_JUNCTIONS_2nd , G_Length , G_Height)
     drain_file_generate(locG_temp , current_NC , 52 , 18, 29 , current_TL , 9.1);
    % 步骤4：运行模型
    % SWMM_model_running(inputfile, report_file, rain, current_NC) 
    %                    输入文件， 运行需要， 降雨数量，节点指定
    % 节点数量索引
    param_index = i;
    result = SWMM_model_running(locG_temp ,locG_temp_report ,rain, current_NC);
    B_G(:,:,i) = result;
    % B_G = (steps ,length(rain) ,param_num) = (2400, 11, 120)
end
    % B_G(:, :, 120)
    size(B_G); 

%% 步骤5：NSE计算（整体代码判断三类参数对全过程NSE和峰值NSE的敏感度
% NSE的敏感性分析
% 1.流量全程的NSE计算
E_flow = NSE_calculation_3d_opticalvision(B_G, A_T);
E_flow_mean = mean(E_flow, 2);

% 2.峰值流量的NSE计算
peak_A_T = max(A_T);   % 每行为原本每页的最大值，仍有11列
peak_B_G = squeeze(max(B_G, [], 1))';
E_calculate = peak_B_G ./ peak_A_T;
E_calculate = 1 - abs(E_calculate-1);  % 注意这里的计算时将NSE都换成                
E_peak_mean = mean(E_calculate, 2);
 
% 后续补充峰值NSE计算，与全程NSE计算保存进E_flow 的第二页
%% 步骤7：峰值流量计算敏感性指标
[metrics, priority] = compute_morris_metrics(E_peak_mean, traj, param_def);
% --- 结果展示 ---
fprintf('\n=== 峰值流量参数敏感性排序 ===\n');
for rank = 1:length(priority)
    param_id = priority(rank);
    fprintf('第%d位: %s (μ*=%.3f, σ=%.3f)\n',...
            rank, metrics(param_id).name, metrics(param_id).mu_star, metrics(param_id).sigma);
end

%% 步骤6：流量全过程计算敏感性指标
[metrics, priority] = compute_morris_metrics(E_flow_mean, traj, param_def);
% --- 结果展示 ---
fprintf('\n=== 流量过程参数敏感性排序 ===\n');
for rank = 1:length(priority)
    param_id = priority(rank);
    fprintf('第%d位: %s (μ*=%.3f, σ=%.3f)\n',...
            rank, metrics(param_id).name, metrics(param_id).mu_star, metrics(param_id).sigma);
end




