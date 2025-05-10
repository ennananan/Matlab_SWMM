function [C] = SWMM_model_running(inputfile, report_file, rain, current_NC) 
% 生成一个二维的2400 * 11的矩阵
% 功能：简便运行swmm，对指定模型进行降雨的更改
    %                             输入文件， 运行需要， 降雨数量，节点指定
 %mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次

%***默认规定 rain_count = 11
% param_index - 是模型写入的参数组合索引
steps = 40 * 60 ;
%rain = [1,2,3,4,5,6,7,8,9,10,11]; % 1a-rainfall
%raincount = length(rain);
%param_num = 1;
%param_index = 1;
%current_NC = 127;


C = zeros(steps ,length(rain));
%inputfile = 'C:\Users\Administrator\Desktop\雨水建模\4-科创概化研究\5-科创园上游概化模型\UR_TModel_ds_3.inp';
%locT = inputfile;
%locT_temp = strrep(locT,'.inp','temp.inp');
%locT_temp_report = strrep(locT_temp,'temp.inp','temp.rpt');
%copyfile(locT, locT_temp);
%report_file = locT_temp_report;

    for raincount = 1:length(rain)

        timeseries_file_generate(inputfile, rain, 59, raincount);
       
        %调用文件位置
        calllib('swmm5' ,'swmm_open' ,inputfile ,report_file ,'' );
        calllib('swmm5' ,'swmm_start' ,1 );
        for k=1:steps
            calllib('swmm5' ,'swmm_stride' ,1 ,1 ); 
            % tip：此处输入的nodes值是在junction list里面的整体order，与数值无关
            % C(k,j) = calllib('swmm5' ,'swmm_getValue' ,307 ,2 ); % G-Model-B-2nodes.ver
            % C(k,gages) = calllib('swmm5' ,'swmm_getValue' ,307 ,3 ); % G-Model-B-3nodes.ver
            C(k ,raincount) = calllib('swmm5' ,'swmm_getValue' ,307 ,current_NC );
        end
        calllib('swmm5','swmm_close');
    end
end

    









