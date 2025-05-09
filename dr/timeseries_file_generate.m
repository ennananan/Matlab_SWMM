function timeseries_file_generate(locG, rain, LOC_RAIN, newValue)

% 文件降雨序列更改
% 注意locG要实际使用temp格式

% mex -setup;loadlibrary('swmm5');%每次重新打开软件都要创建一次

% 概化模型 — G-Model

%模型文件格式整理
%locG_temp=strrep(locG,'.inp','temp.inp');
locG_temp = locG;
%locG_temp_report=strrep(locG_temp,'temp.inp','temp.rpt');
%copyfile(locG,locG_temp); 

%======基础表格统计结果设置========
%LOC_RAIN = 59;

%【RAINGAGES】       

% RAINGAGES 写入
sectionLine = findInpSectionLine(locG_temp , 'RAINGAGES');
 % replaceInpValue_write_in(inpFile, tempFile, sectionLine, n, l, newValue)
replaceInpValue_write_in(locG_temp ,locG_temp ,sectionLine ,1 ,LOC_RAIN , newValue);

end