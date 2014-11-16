addpath('mksqlite');
addpath('includes');

close all; clc

drop_tables
fp1 = ForexPredictor('forex_predictor.db', 'try', 5);
fp1.setPredictionCSVPath('predictions.csv');
fp1.memorizeCSV('t0.5n5/training_x.csv', 'x');
fp1.memorizeCSV('t0.5n5/training_y.csv', 'y');
fp1.predictCSV('t0.5n5/cross-validation_x.csv');

% We can later compare multiple forex prediction sessions:
% fp2 = ForexPredictor('forex_predictor.db', 'try');
% fp2.memorizeCSV('t0.5n5/training_x.csv', 'x');
% fp2.memorizeCSV('t0.5n5/training_y.csv', 'y');
% fp2.predictCSV('t0.5n5/cross-validation_x.csv');

% On live expert advisor mode, process as follows:
% fp3 = ForexPredictor('forex_predictor.db', 'try');
% fp3.memorize('x', fields, x_of_past_5_days);
% fp3.memorize('y', fields, ???problem is y of yesterday cannot be
% found???)