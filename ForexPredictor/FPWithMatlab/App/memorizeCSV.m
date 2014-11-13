% Get from CSV
% Entered into SQL
function output = memorizeCSV(csv_location, table_name)
    X = dlmread(csv_location, ',', 1, 0);
    X_size = size(X);
    text = '';
    for i=1:X_size(1,2)-1
        text = strcat(text, '%[^,],');
    end
    fid = fopen(csv_location, 'r');
    fields = textscan(fid, strcat(text,'%[^,\r\n]'), 1);
    fclose(fid);
    
    memorize(table_name, fields, X);
    output = true;
end