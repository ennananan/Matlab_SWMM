function E = NSE_calculation_un2(A, B)
% 计算Nash-Sutcliffe效率系数
% 输入:
%   A - 观测数据矩阵 (n×m)
%   B - 模拟数据矩阵 (n×m)
% 输出:
%   E - 各列的NSE系数 (m×1向量)

% 参数校验
validateattributes(A, {'numeric'}, {'2d','nonempty'}, 1);
validateattributes(B, {'numeric'}, {'size',size(A)}, 2);

% 向量化计算
obs_mean = mean(A, 1);              % 各列均值 (1×m)
numerator = sum(abs(A - B), 1);     % 分子：模拟误差平方和 (1×m)
denominator = sum(abs(A - obs_mean), 1); % 分母：观测方差和 (1×m)

% 处理零方差情况
valid_cols = (denominator > eps);   % 排除零方差列
E = NaN(size(obs_mean));            % 预分配带NaN的结果
E(valid_cols) = 1 - numerator(valid_cols) ./ denominator(valid_cols);

% 转置为列向量
E = E(:);
end