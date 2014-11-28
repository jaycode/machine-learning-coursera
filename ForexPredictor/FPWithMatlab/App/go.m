addpath('mksqlite');
addpath('includes');

close all; clc

drop_tables
fp1 = ForexPredictor('forex_predictor.db', 'try', 5);
fp1.setPredictionCSVPath('predictions.csv');
fp1.memorizeCSV('inputs/training_inputs.csv', 'inputs');
fp1.memorizeCSV('inputs/training_targets.csv', 'targets');
fp1.memorizeCSV('inputs/testing_inputs.csv', 'inputs');
fp1.memorizeCSV('inputs/testing_targets.csv', 'targets');
fp1.setupXY('inputs', 'targets');
% fp1.experiment('inputs/testing_inputs.csv', 'inputs/testing_targets.csv');
fp1.predictCSV('inputs/testing_inputs.csv', 'outputs');

% We can later compare multiple forex prediction sessions:
% fp2 = ForexPredictor('forex_predictor.db', 'try');
% fp2.memorizeCSV('inputs/training_x.csv', 'x');
% fp2.memorizeCSV('inputs/training_targets.csv', 'targets');
% fp2.predictCSV('inputs/testing_x.csv');

% On live expert advisor mode, process as follows:
% fp3 = ForexPredictor('forex_predictor.db', 'try');
% fp3.memorize('x', fields, x_of_past_5_days);
% fp3.memorize('y', fields, ???problem is y of yesterday cannot be
% found???)