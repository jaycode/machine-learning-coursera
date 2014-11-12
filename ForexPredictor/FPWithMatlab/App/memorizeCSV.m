% Get from CSV
% Entered into SQL
function output = memorizeCSV()
    addpath('mksqlite');
    mksqlite('open','forex_predictor.db');
    mksqlite('INSERT INTO x_daily (ID, time) VALUES (NULL, 1.123)');
    output = 1;
end