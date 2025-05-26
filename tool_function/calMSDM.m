function MSDM = calMSDM(B_G, window_size)
% calcMSDM 计算给定时间序列的滑动标准差均值（MSDM）
%
% 输入：
%   Q_G         - 时间序列向量（例如流量数据）
%   window_size - 滑动窗口大小（正奇数或偶数均可）
%
% 输出：
%   MSDM        - 滑动标准差的均值（衡量局部抖动强度）

    n = length(B_G);
    mov_std = zeros(n,1);
    half_win = floor(window_size / 2);

    for i = 1:n
        idx_start = max(1, i - half_win);
        idx_end = min(n, i + half_win);
        window_data = B_G(idx_start:idx_end);
        mov_std(i) = std(window_data);
    end

    MSDM = mean(mov_std);

end
