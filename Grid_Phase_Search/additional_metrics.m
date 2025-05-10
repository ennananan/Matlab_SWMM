function [peak_error, peak_time_error, mov_std_mean] = additional_metrics(Q_G, Q_T, dt)
% 输入：
% Qsim: 模拟流量（列向量）
% Qobs: 观测流量（列向量）
% dt: 时间步长

% 峰值误差, 越小越好
% peak_error = abs(max(Q_G) - max(Q_T)) / max(Q_T); % 这两个公式一个意思
peak_error = abs((max(Q_G) / max(Q_T)) - 1);


% 峰值出现时间误差
[~, idx_sim] = max(Q_G);
[~, idx_obs] = max(Q_T);
peak_time_error = (idx_sim - idx_obs) * dt / 60; % 分钟

% 二阶差分稳定性指标
% second_diff = diff(Q_G, 2); % 二阶差分
% SOD_value = mean(second_diff.^2);

%% 3. 滑动标准差均值（局部抖动指标）
    window_size = 10; % 滑动窗口大小，可根据需要调整
    n = length(Q_G);
    mov_std = zeros(n,1);

    half_win = floor(window_size/2);

    for i = 1:n
        idx_start = max(1, i - half_win);
        idx_end = min(n, i + half_win);
        window_data = Q_G(idx_start:idx_end);
        mov_std(i) = std(window_data);
    end

    mov_std_mean = mean(mov_std); % 整条曲线的滑动标准差均值

end



