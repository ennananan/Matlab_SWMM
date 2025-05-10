function [R]=NSE_calculation_3D(A, B)
% 计算三维数组间的纳什效率系数（每个参数组和降雨事件独立计算）
% A - 概化模型；B - 孪生模型
% 检查维度一致性
if ~isequal(size(A), size(B))
    error('输入数组维度不匹配');
end

% 初始化输出矩阵
[steps, paramgap, rain_count] = size(A);
R = zeros(paramgap, rain_count);

% 并行计算每个参数组和降雨事件
parfor k = 1:rain_count
    for j = 1:paramgap
        % 提取当前参数组和降雨事件的时间序列
        a = A(:, j, k);
        b = B(:, j, k);
        
        % 计算残差平方和
        residual = a - b;
        m = sum(residual.^2);
        
        % 计算观测值方差
        obs_mean = mean(b)
        obs_var = sum((b - obs_mean).^2);
        
        % 处理零方差情况
        if obs_var == 0
            R(j, k) = NaN;
        else
            R(j, k) = 1 - m / obs_var;
        end
    end
end
end