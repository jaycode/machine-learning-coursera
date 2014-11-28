classdef ForexPredictor3Labels
    % ForexPredictor class
    properties (SetAccess = private)
        dbname, tableset_name, prediction_days, prediction_csv_path, settings_csv_path, dbg
    end
    
    properties (SetAccess = public)
        x_table_name = 'x';
        y_table_name = 'y';
        upper_threshold = 1;
        lower_threshold = -2;
        training_limit = 300; % Limit of training rows per target signal (i.e. x number of buy and sell signals each).
        hidden_layer_size = 5;
        lambda = 0.1;
    end
    
    %% Public methods:
    methods
        %% Initialization method
        function fp = ForexPredictor(input_dbname, tableset_name, prediction_days)
            fp.dbname = input_dbname;
            fp.tableset_name = tableset_name;
            fp.prediction_days = prediction_days;
            fp.prediction_csv_path = 'predictions.csv';
            fp.settings_csv_path = 'settings.csv';
            mksqlite('open', fp.dbname);
        end
        
        %% Sets production CSV path
        function setPredictionCSVPath(obj, path)
            obj.prediction_csv_path = path;
        end
        
        %% Gets inputs for x, y, or targets from CSV
        % Enter into SQL
        % table_suffix: 'x' or 'y' or 'targets'
        % First field of CSV MUST be time since we need that for prediction id.
        function memorizeCSV(obj, csv_location, table_suffix)
            fprintf(['\nMemorizing ',table_suffix,'...\n'])
            X = dlmread(csv_location, ',', 1, 0);
            X_size = size(X);
            text = '';
            for i=1:X_size(1,2)-1
                text = strcat(text, '%[^,],');
            end
            fid = fopen(csv_location, 'r');
            fields = textscan(fid, strcat(text,'%[^,\r\n]'), 1);
            fclose(fid);

            obj.memorize(table_suffix, fields, X);
        end
        
        %% Inputs variants to SQL
        % First field & value must be time!
        function memorize(obj, table_suffix, fields, values)
            table_name = strcat(obj.tableset_name, '_', table_suffix);
            mksqlite('open',obj.dbname);
            fields = fields(2:size(fields,2));
            times = values(:,1);
            values = values(:,2:size(values,2));
            [create_fields_text, fields_text] = ForexPredictor.combineFields(fields);

            sql_create = strcat('CREATE TABLE IF NOT EXISTS', {' `'}, table_name, '`(', create_fields_text, ')');
            mksqlite(sql_create{1});

            last = 0;
            max_batch = 400;
            while 1
                if size(values, 1) < last + max_batch
                    batch = size(values, 1);
                else
                    batch = last + max_batch;
                end
                values_text = '';
                for i=last+1:batch
                    if (isnumeric(times(i)))
                        time = ForexPredictor.unix2sqlite(times(i));
                    else
                        time = times(i);
                    end
                    value_text = strcat('(strftime(''', time , '''),', num2str(values(i, 1)));

                    for j=2:size(values,2)
                        value_text = strcat(value_text, ',', num2str(values(i, j)));
                    end
                    value_text = strcat(value_text, ')');
                    if i == last+1
                        values_text = value_text;
                    else
                        values_text = strcat(values_text, ',', value_text);
                    end
                end
                sql_insert = strcat('INSERT INTO', {' `'}, table_name, '` (', fields_text, ') VALUES', {' '}, values_text);
                mksqlite(sql_insert{1});
                last = batch;
                if (batch >= size(values, 1)); break; end
            end
            % delete duplicates
            sql_delete = strcat('DELETE FROM `',table_name,'`',...
                         'WHERE `id` NOT IN ',...
                         '(SELECT MIN(`id`) ',...
                         ' FROM `',table_name,'`',...
                         ' GROUP BY time',...
                         ')');
            mksqlite(sql_delete);
        end
        
        %% Predicts from a given csv file
        %  and export to another csv file located in given
        %  output_directory. Output csvs are predictions.csv containing the
        %  predictions, and settings.csv containing the settings required
        %  by Expert Advisor's ApplyPrediction methods. Copy both files to
        %  Files/ForexPredictor directory in MQL dir.
        function predictCSV(obj, csv_location, output_directory)
            X = dlmread(csv_location, ',', 1, 0);
            X_size = size(X,1);
            text = '';
            for i=1:size(X,2)-1
                text = strcat(text, '%[^,],');
            end
            
            if ~exist(output_directory, 'dir')
                mkdir(output_directory);
            end
            
            fid=fopen(strcat(output_directory, '/', obj.prediction_csv_path),'wt');
            fprintf(fid,'time,signal,confidence\n');
            num_trades_buy = 0;
            num_trades_sell = 0;
            num_trades_hold = 0;
            for i=1:X_size
                prediction = obj.predict(X(i,:));
                if (prediction{2} == 1)
                    num_trades_buy=num_trades_buy+1;
                elseif (prediction{2} == 2)
                    num_trades_sell=num_trades_sell+1;
                else
                    num_trades_hold=num_trades_hold+1;
                end

                csvFun = @(val)sprintf('%s, ',num2str(val));
                xchar = cellfun(csvFun, prediction, 'UniformOutput', false);
                xchar = strcat(xchar{:});
                xchar = strcat(xchar(1:end-1),'\n');
                fprintf(fid,xchar);
                
                fprintf('%d out of %d\n', [i,X_size]);
            end
            fclose(fid);
            
            fid=fopen(strcat(output_directory, '/', obj.settings_csv_path),'wt');
            fprintf(fid,strcat('upper_threshold,', num2str(obj.upper_threshold), '\n'));
            fprintf(fid,strcat('lower_threshold,', num2str(obj.lower_threshold), '\n'));
            fclose(fid);
            
            fprintf('buy trades: %d sell trades: %d hold: %d total: %d\n', num_trades_buy, num_trades_sell, num_trades_hold, (num_trades_buy + num_trades_sell + num_trades_hold));
        end
        
        %% Predicts one line of features.
        % prediction is an array of time, signal, and confidence.
        % (maybe later we will add take profit, cut loss, and volume)
        function prediction = predict(obj, x)
            [Theta1, Theta2] = obj.learn(x(1));
            % get x but without first field (i.e. time).
            [signal, confidence] = predict(Theta1, Theta2, x(:,2:end));
            prediction = {int32(x(1)), signal, confidence};
        end
        
        %% Choose the right inputs and targets to create x and y.
        function setupXY(obj, inputs_table_name, targets_table_name)
            fprintf('\nSetup XY...\n')
            limit = obj.training_limit;
            upper_t = obj.upper_threshold;
            lower_t = obj.lower_threshold;

            % Select n% threshold targets for buy signals.
            fields = {'signal', 'bids', 'asks', 'maxminclose', 'target'};
            [create_fields_text, fields_text] = ForexPredictor.combineFields(fields);
            
            sql_create = strcat('CREATE TABLE IF NOT EXISTS', {' `'}, obj.tableset_name,'_',obj.y_table_name, '`(', create_fields_text, ', UNIQUE(time))');
            mksqlite(sql_create{1});
            sql = strcat('INSERT OR IGNORE INTO `',obj.tableset_name,'_',obj.y_table_name,'` ( ',fields_text,' ) ', ...
                ' SELECT time, 1 as signal, bids, asks, maxclose, uppertarget FROM `', ...
                obj.tableset_name,'_',targets_table_name,'` WHERE uppertarget >= ? AND lowertarget > ?', ...
                ' ORDER BY time DESC LIMIT ?');
            mksqlite(sql, upper_t, lower_t, limit);

            % Select n% threshold targets for sell signals.
            sql = strcat('INSERT OR IGNORE INTO `',obj.tableset_name,'_',obj.y_table_name,'` ( ',fields_text,' ) ', ...
                'SELECT time, 2 as signal, bids, asks, minclose, lowertarget FROM `', ...
                obj.tableset_name,'_',targets_table_name,'` WHERE lowertarget <= ? AND uppertarget < ?', ...
                ' ORDER BY time DESC LIMIT ?');
            mksqlite(sql, lower_t, upper_t, limit);
            
            % Select targets for hold signals.
            sql = strcat('INSERT OR IGNORE INTO `',obj.tableset_name,'_',obj.y_table_name,'` ( ',fields_text,' ) ', ...
                'SELECT time, 0 as signal, bids, asks, minclose, lowertarget FROM `', ...
                obj.tableset_name,'_',targets_table_name,'` WHERE lowertarget > ? AND uppertarget < ?', ...
                ' ORDER BY time DESC LIMIT ?');
            mksqlite(sql, lower_t, upper_t, limit);
            
            
            % Now create the x table
            sql = strcat('PRAGMA table_info(`',obj.tableset_name,'_',inputs_table_name,'`)');
            data = mksqlite(sql);
            fields = arrayfun(@(x) [x.name], data, 'UniformOutput', false);
            fields = fields(3:end);
            [create_fields_text, fields_text] = ForexPredictor.combineFields(fields);
            
            fields_text2 = strcat('`',obj.tableset_name,'_',inputs_table_name, '`.`time`, `',obj.tableset_name,'_',inputs_table_name, '`.`', fields{1}, '`');
            for i=2:size(fields,1)
                fields_text2 = strcat(fields_text2, ',`', obj.tableset_name,'_',inputs_table_name, '`.`', fields{i}, '`');
            end
            sql_create = strcat('CREATE TABLE IF NOT EXISTS', {' `'}, obj.tableset_name,'_',obj.x_table_name, '`(', create_fields_text, ', UNIQUE(time))');
            mksqlite(sql_create{1});
            sql = strcat('INSERT OR IGNORE INTO `',obj.tableset_name,'_',obj.x_table_name,'` ( ',fields_text,' ) ', ...
                'SELECT ',fields_text2,' FROM `', ...
                obj.tableset_name,'_',inputs_table_name,'`, `',obj.tableset_name,'_',obj.y_table_name,...
                '` WHERE `',obj.tableset_name,'_',inputs_table_name,'`.time = `',obj.tableset_name,'_',obj.y_table_name,'`.time ORDER BY `',obj.tableset_name,'_',obj.y_table_name,'`.id');
            mksqlite(sql);
        end
        
        %% Experiment
        function experiment(obj, inputs_csv, outputs_csv)
            fprintf('\nExperimenting...\n')
            [Theta1, Theta2, X, y, input_layer_size, num_labels, initial_nn_params] = obj.learn();
            upper_t = obj.upper_threshold;
            lower_t = obj.lower_threshold;
            inputs = dlmread(inputs_csv, ',',1,1);
            outputs = dlmread(outputs_csv, ',',1,1);
            signal_outputs = zeros(size(outputs,1),1);
            for i=1:size(outputs,1)
                if (outputs(i,5)>=upper_t && outputs(i,6)>lower_t)
                    signal_outputs(i)=1;
                end
                if (outputs(i,6)<=lower_t && outputs(i,5)<upper_t)
                    signal_outputs(i) = 2;
                end
            end
%             keyboard;
%             Xval = dlmread([directory, '/cross-validation_x.csv'], ',', 1, 1);
%             fid = fopen([directory, '/cross-validation_y.csv']);
%             exp=textscan(fid, '%d %f %f %f %f %s', 'HeaderLines', 1, 'Delimiter', ',');
%             fclose(fid);
%             yval = exp{2};
            Xval = inputs;
            yval = signal_outputs;
            [pred_val, confidence_val] = predict(Theta1, Theta2, Xval);
            fprintf('\nCrossvalidation Set Accuracy: %f\n', mean(double(pred_val == yval)) * 100);

            experiment(X,y,Xval, yval, input_layer_size, ...
                                obj.hidden_layer_size, num_labels, ...
                                initial_nn_params, obj.lambda);
        end
    end
    
    %% Private methods
    methods(Access=private)
        %% Preparation before learning, e.g.
        % choosing which data to use when learning.
        function prelearn(obj, time)
        end
        %% Learning from current training data.
        % Data used are ones before given time.
        function [Theta1, Theta2, X, y, input_layer_size, num_labels, initial_nn_params] = learn(obj, time)
            if (nargin < 2)
                time = ForexPredictor.sqlite2unix('2114-01-13 00:00');
            end
            obj.prelearn(time);
            % Setup the parameters
            num_labels = 3;
            fprintf('\nLoading training data ...\n')
            last_training_time = time - (60*60*24*obj.prediction_days);
            sql = strcat('SELECT * FROM `', obj.tableset_name, '_',obj.x_table_name,'` WHERE time < ? ORDER BY time desc');
            data = mksqlite(sql, ForexPredictor.unix2sqlite(last_training_time));
            fields = fieldnames(data);
            caller = '';
            for i=3:size(fields,1)
                caller = [caller, ' x.', fields{i}];
            end
            caller = sprintf('cell2mat(arrayfun(@(x) [%s], data, ''UniformOutput'', false))', caller);
            X = eval(caller);

            input_layer_size  = size(fields,1) - 2;

            data = mksqlite(['SELECT signal FROM `', obj.tableset_name, '_',obj.y_table_name,'` WHERE time < ? ORDER BY time desc'], ForexPredictor.unix2sqlite(last_training_time));
            y = arrayfun(@(x) [x.signal], data);
            Xy = [X y];
            Xy = Xy(randperm(size(Xy,1)),:);
            X = Xy(:,1:end-1);
            y = Xy(:,end);
            
            initial_Theta1 = randInitializeWeights(input_layer_size, obj.hidden_layer_size);
            initial_Theta2 = randInitializeWeights(obj.hidden_layer_size, num_labels);

            initial_nn_params = [initial_Theta1(:) ; initial_Theta2(:)];

            fprintf('\nChecking Backpropagation... \n');

            %  Change the MaxIter to a larger
            %  value to see how more training helps.
            options = optimset('MaxIter', 100);

            % checkNNGradients(obj.lambda);

            fprintf('\nChecking Cost Function \n')

            % Create "short hand" for the cost function to be minimized
            costFunction = @(p) nnCostFunction(p, ...
                                               input_layer_size, ...
                                               obj.hidden_layer_size, ...
                                               num_labels, X, y, obj.lambda);

            % Now, costFunction is a function that takes in only one argument (the
            % neural network parameters)
            [nn_params, cost] = fmincg(costFunction, initial_nn_params, options);

            % Obtain Theta1 and Theta2 back from nn_params
            Theta1 = reshape(nn_params(1:obj.hidden_layer_size * (input_layer_size + 1)), ...
                             obj.hidden_layer_size, (input_layer_size + 1));

            Theta2 = reshape(nn_params((1 + (obj.hidden_layer_size * (input_layer_size + 1))):end), ...
                             num_labels, (obj.hidden_layer_size + 1));

            fprintf('Cost: %f ', cost);
            [signal, confidence] = predict(Theta1, Theta2, X);
            fprintf('\nTraining Set Accuracy: %f\n', mean(double(signal == y)) * 100);
        end
    end
    methods(Static)
        function tu = sqlite2unix(tm)
            tu = round(86400 * (datenum(tm, 'yyyy-mm-dd HH:MM') - datenum('1970', 'yyyy')));
        end
        function tm = unix2sqlite(tu)
            tm = datestr(datenum('1970', 'yyyy') + tu / 86400, 'yyyy-mm-dd HH:MM');
        end
        function [create_fields_text, fields_text] = combineFields(fields)
            create_fields_text = strcat('`id` INTEGER PRIMARY KEY AUTOINCREMENT,time DATETIME,`',fields{1}, '` DOUBLE');
            fields_text = strcat('`time`,`', fields{1},'`');
            if (size(fields,2) > size(fields,1))
                the_size = size(fields,2);
            else
                the_size = size(fields,1);
            end
            for i=2:the_size
                create_fields_text = strcat(create_fields_text, ',`', fields{i}, '` DOUBLE');
                fields_text = strcat(fields_text, ',`', fields{i}, '`');
            end
        end
    end
    
end

