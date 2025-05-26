function [MSDM_A, MSDM_B, corr_movstd, mov_std_A, mov_std_B] = compareMSDM(A, B, window_size)
% compareMSDM 比较两个流量过程的滑动标准差（局部波动）一致性
%
% 输入：
%   A, B         - 两个待比较的模型输出矩阵 (time_steps × series_count)
%   window_size  - 滑动窗口大小
%
% 输出：
%   MSDM_A, MSDM_B   - 两模型的滑动标准差均值（整体局部波动强度）
%   corr_movstd      - 平均局部波动相关性（衡量局部趋势一致性）
%   mov_std_A/B      - 每个序列的滑动标准差曲线 (time_steps × series_count)

    [n, m] = size(A);
    mov_std_A = zeros(n, m);
    mov_std_B = zeros(n, m);

    half_win = floor(window_size / 2);

    for j = 1:m
        for i = 1:n
            idx_start = max(1, i - half_win);
            idx_end = min(n, i + half_win);
            mov_std_A(i,j) = std(A(idx_start:idx_end, j));
            mov_std_B(i,j) = std(B(idx_start:idx_end, j));
        end
    end

    MSDM_A = mean(mov_std_A(:));
    MSDM_B = mean(mov_std_B(:));

    % 计算每组序列的滑动标准差曲线相关性
    corr_list = zeros(1, m);
    for j = 1:m
        r = corrcoef(mov_std_A(:,j), mov_std_B(:,j));
        corr_list(j) = r(1,2);
    end

    corr_movstd = mean(corr_list); % 趋势一致性的整体度量

end
