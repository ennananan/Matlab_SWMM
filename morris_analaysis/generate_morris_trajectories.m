function [traj, delta] = generate_morris_trajectories(param_def, r)
    % 生成满足约束条件的Morris轨迹
    % 输入：
    %   param_def - 参数定义cell数组
    %   r - 轨迹数量
    % 输出：
    %   traj - 轨迹矩阵(n×(k+1),k)
    %   delta - 各参数步长
    
    k = size(param_def,1); % 参数个数
    p = 6; % 离散化水平数
    
    traj = zeros(r*(k+1), k);
    delta = zeros(1,k);
        for i = 1:r
        % 生成有效初始点
        valid = false;
        while ~valid
            % 生成随机起点
            %x0 = cell2mat(cellfun(@(x) x{3}(1) + (x{3}(2)-x{3}(1)).*rand(1), param_def, 'UniformOutput', false));
            % 自行修改1, 注：rand使得x0每次结果都不一致
            x0 = cell2mat(cellfun(@(x) x(1) + (x(2)-x(1)).*rand(1),param_def(:,3), 'UniformOutput', false));

            % 处理整数参数
            int_idx = strcmp('integer', param_def(:,2));
            x0(int_idx) = round(x0(int_idx));
            %x0
            % 有效性验证
            check_validity = @(x) x(1)/(x(2)+1) >= 10; % 单管长≥10m约束
            valid = check_validity(x0);
        end
        
        % 计算离散步长
        delta = cellfun(@(x) (x(2)-x(1))/(p-1), param_def(:,3));
        delta(int_idx) = round(delta(int_idx)); % 整数步长取整
        %delta
        % 构建单条轨迹
        traj_i = zeros(k+1, k);%可能存在的命名问题，i，结构体方式解决
        traj_i(1,:) = x0;
        for j = 1:k
            traj_i(j+1,:) = traj_i(j,:);
            new_val = traj_i(j,j) + delta(j);
            
            % 边界处理
            if new_val > param_def{j,3}(2)
                new_val = param_def{j,3}(1) + (new_val - param_def{j,3}(2));
            elseif new_val < param_def{j,3}(1)
                new_val = param_def{j,3}(2) - (param_def{j,3}(1) - new_val);
            end
            
            traj_i(j+1,j) = new_val;
            
            % 保持整数约束
            if strcmp(param_def{j,2}, 'integer')
                traj_i(j+1,j) = round(traj_i(j+1,j));
            end
        end
        
        % 存入总轨迹矩阵
        traj((i-1)*(k+1)+1:i*(k+1), :) = traj_i;
    end
    %traj
    %traj_i
    format short;
end
