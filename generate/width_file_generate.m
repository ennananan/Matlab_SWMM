function width_file_generate(locG , LOC_SUBCATCHMENT, G_Width)
 % 功能：仅用于在INP文件中 漫流宽度 写入
 % 
 % tempFile - temp.inp文件名称
 % sectionName - 寻找的模型对象名称
 % newValue - 所要替换的值
 % 漫流宽度 写入
 locG_temp = locG;
sectionLine = findInpSectionLine(locG_temp , 'SUBCATCHMENTS');

%确保两位小数写入
G_Width = round(G_Width *100 ) / 100;
replaceInpValue_write_in(locG_temp ,locG_temp ,sectionLine ,1 ,LOC_SUBCATCHMENT , G_Width);

 