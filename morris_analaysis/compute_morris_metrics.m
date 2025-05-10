function [metrics, priority] = compute_morris_metrics(Y, traj, param_def)
% 计算Morris敏感性指标（适配generate_morris_trajectories生成的轨迹结构）
% 输入：
%   Y - 模型输出矩阵（样本数 × 指标数）
%   traj - 轨迹矩阵（样本数 × 参数数）
%   param_def - 参数定义元胞数组
% 输出：
%   metrics - 敏感性指标结构体
%   priority - 参数综合敏感度排序

%% 参数维度验证

% 正确提取参数范围矩阵（处理行向量存储格式）
param_ranges = cell2mat(cellfun(@(x) x(:)', param_def(:,3), 'UniformOutput', false)); % 强制转为行向量
lower_bounds = param_ranges(:,1);   % 3×1列向量 [50; 1; 200]
upper_bounds = param_ranges(:,2);   % 3×1列向量 [350; 8; 2500]
param_spans = upper_bounds - lower_bounds; % 3×1列向量 [300;7;2300]

% 防止零跨度参数导致除零错误
param_spans(param_spans == 0) = 1; 
% 轨迹数据重塑
k = size(param_def,1);
r = size(traj,1)/(k+1);
% 轨迹归一化（关键维度广播操作）
traj_norm = (traj - lower_bounds') ./ param_spans'; % 120×3矩阵

% 重塑为轨迹 × 样本 × 参数（使用归一化后的轨迹）
traj_3d = permute(reshape(traj_norm, k+1, r, k), [2 1 3]);
% 验证维度:
% size(traj_3d) = r × (k+1) × k
Y_reshaped = permute(reshape(Y, k+1, r), [2 1]);
% 维度: 
% r × (k+1) × rain_num × nse_num
%% --- 初始化存储结构 ---
metrics = struct();
for param_idx = 1:k
    metrics(param_idx).name = param_def{param_idx,1};
    metrics(param_idx).mu = 0; % 均值μ
    metrics(param_idx).mu_star = 0;  % 绝对均值μ*
    metrics(param_idx).sigma = 0;    % 标准差σ
end

%% 核心计算流程（修正分母错误）
for param_idx = 1:k
    % 获取归一化后的参数轨迹（维度: r × (k+1)）
    param_traj_norm = traj_3d(:,:,param_idx); % 每页代表一个参数的更改变化
    
    % 检测参数变化步骤（基于归一化值）
    delta_mask = [false(r,1), diff(param_traj_norm,1,2) ~= 0];
    [traj_list, step_list] = find(delta_mask);
    
    % if length(traj_list) ~= r
    %    warning('参数 %s 在部分轨迹中未变化，结果可能不准确', metrics(param_idx).name);
    %    continue;
    %end

      % 计算归一化步长（使用第一个有效变化）
    %first_traj = traj_list(:,1); % 1-30
    first_step = step_list(1); % 参数变化过程
    delta_p = param_traj_norm(:, first_step) - ...
              param_traj_norm(:, first_step-1); %计算更改参数差值

    % --- 改进的基本效应计算 ---
    %EE = zeros(length(traj_list),1);  % 预分配内存
    delta_Y = zeros(length(traj_list),1);
    for idx = 1:length(traj_list)
       % traj_id = traj_list(idx);
        step_id = step_list(idx);

        % 获取输出变化（单指标）
        delta_Y= Y_reshaped(:, step_id) - Y_reshaped(:, step_id-1);  
        
        % 存储当前参数的基本效应
       
    end
    EE = delta_Y ./ delta_p;
    
    % --- 统计量计算 ---
    metrics(param_idx).mu = mean(EE);
    metrics(param_idx).mu_star = mean(abs(EE));  
    metrics(param_idx).sigma = std(EE);
end

% param_traj_norm
% first_traj
% first_step 

%% --- 综合排序（按mu_star降序） ---
mu_star_values = [metrics.mu_star];
[~, priority] = sort(mu_star_values, 'descend');

end

