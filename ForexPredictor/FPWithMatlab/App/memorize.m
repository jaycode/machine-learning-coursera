% Input variants to SQL
function output = memorize(table_name, fields, values, first_field_is_time)
    if nargin < 4
        first_field_is_time = true;
    end
    addpath('mksqlite');
    addpath('includes');
    mksqlite('open','forex_predictor.db');
    if (first_field_is_time)
        fields = fields(2:size(fields,2));
        times = values(:,1);
        values = values(:,2:size(values,2));
        create_fields_text = strcat('`id` INTEGER PRIMARY KEY AUTOINCREMENT,time DATETIME,`',fields{1}, '` DOUBLE');
        fields_text = strcat('`time`,`', fields{1},'`');
    else 
        create_fields_text = strcat('`id` INTEGER PRIMARY KEY AUTOINCREMENT,`',fields{1}, '` DOUBLE');
        fields_text = strcat('`',fields{1},'`');
    end
    
    for i=2:size(fields,2)
        fields_text = strcat(fields_text, ',`', fields{i}, '`');
        create_fields_text = strcat(create_fields_text, ',`', fields{i}, '` DOUBLE');
    end
    values_text = '';
    for i=1:size(values, 1)
        if (first_field_is_time)
            value_text = strcat('(''', unix2matlab(times(i)) , ''',', num2str(values(i, 1)));
        else
            value_text = strcat('(', num2str(values(i, 1)));
        end
        for j=2:size(values,2)
            value_text = strcat(value_text, ',', num2str(values(i, j)));
        end
        value_text = strcat(value_text, ')');
        if i == 1
            values_text = value_text;
        else
            values_text = strcat(values_text, ',', value_text);
        end
    end
    sql_create = strcat('CREATE TABLE IF NOT EXISTS', {' `'}, table_name, '`(', create_fields_text, ')');
    sql_insert = strcat('INSERT INTO', {' `'}, table_name, '` (', fields_text, ') VALUES', {' '}, values_text);
    mksqlite(sql_create{1});
    mksqlite(sql_insert{1});
    output = true;
end