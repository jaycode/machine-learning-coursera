classdef ForexPredictor
    % ForexPredictor class
    properties (SetAccess = private)
        dbname, tableset_name, prediction_days, prediction_csv_path
    end
    
    %% Public methods:
    methods
        %% Initialization method
        function fp = ForexPredictor(input_dbname, tableset_name, prediction_days)
            fp.dbname = input_dbname;
            fp.tableset_name = tableset_name;
            fp.prediction_days = prediction_days;
            fp.prediction_csv_path = 'predictions.csv';
            mksqlite('open', fp.dbname);
        end
        
        %% Sets production CSV path
        function setPredictionCSVPath(obj, path)
            obj.prediction_csv_path = path;
        end
        
        %% Gets inputs for x or y from CSV
        % Enter into SQL
        % table_suffix: 'x' or 'y'
        % First field of CSV MUST be time since we need that for prediction id.
        function memorizeCSV(obj, csv_location, table_suffix)
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
        function memorize(obj, table_suffix, fields, values)
            table_name = strcat(obj.tableset_name, '_', table_suffix);
            mksqlite('open',obj.dbname);
            
            fields = fields(2:size(fields,2));
            times = values(:,1);
            values = values(:,2:size(values,2));
            create_fields_text = strcat('`id` INTEGER PRIMARY KEY AUTOINCREMENT,time DATETIME,`',fields{1}, '` DOUBLE');
            fields_text = strcat('`time`,`', fields{1},'`');

            for i=2:size(fields,2)
                fields_text = strcat(fields_text, ',`', fields{i}, '`');
                create_fields_text = strcat(create_fields_text, ',`', fields{i}, '` DOUBLE');
            end
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
                    value_text = strcat('(strftime(''', ForexPredictor.unix2sqlite(times(i)) , '''),', num2str(values(i, 1)));

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
        end
        
        %% Predicts from a given csv file
        function predictCSV(obj, csv_location)
            X = dlmread(csv_location, ',', 1, 0);
            X_size = size(X,1);
            text = '';
            for i=1:size(X,2)-1
                text = strcat(text, '%[^,],');
            end
            
            fid=fopen(obj.prediction_csv_path,'wt');
            for i=1:X_size
                prediction = obj.predict(X(i,:));

                csvFun = @(val)sprintf('%s, ',num2str(val));
                xchar = cellfun(csvFun, prediction, 'UniformOutput', false);
                xchar = strcat(xchar{:});
                xchar = strcat(xchar(1:end-1),'\n');
                fprintf(fid,xchar);
                
                fprintf('%d out of %d', [i,X_size]);
            end
            fclose(fid);
            
            % csvwrite(obj.prediction_csv_path,predictions);
        end
        
        %% Predicts one line of features.
        % prediction is an array of time, signal, and confidence.
        % (maybe later we will add take profit, cut loss, and volume)
        function prediction = predict(obj, x)
            % add to x table
            % table_name = strcat(obj.tableset_name, '_x');
            % mksqlite(['INSERT INTO `', table_name ,'` VALUES (null, ' , values_text , ')']);
            [Theta1, Theta2] = obj.learn(x(1));
            % get x but without first field (i.e. time).
            [signal, confidence] = predict(Theta1, Theta2, x(:,2:end));
            prediction = {int32(x(1)), signal, confidence};
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
        function [Theta1, Theta2] = learn(obj, time)
            obj.prelearn(time);
            % Setup the parameters
            hidden_layer_size = 4;
            num_labels = 2;

            fprintf('\nLoading training data ...\n')
            last_training_time = time - (60*60*24*obj.prediction_days);
            sql = strcat('SELECT * FROM `', obj.tableset_name, '_x` WHERE time < ?');
            data = mksqlite(sql, ForexPredictor.unix2sqlite(last_training_time));
            fields = fieldnames(data);
            caller = '';
            for i=3:size(fields,1)
                caller = [caller, ' x.', fields{i}];
            end
            caller = sprintf('cell2mat(arrayfun(@(x) [%s], data, ''UniformOutput'', false))', caller);
            X = eval(caller);

            input_layer_size  = size(fields,1) - 2;

            data = mksqlite(['SELECT signal FROM `', obj.tableset_name, '_y` WHERE time < ?'], ForexPredictor.unix2sqlite(last_training_time));
            y = arrayfun(@(x) [x.signal], data);

            initial_Theta1 = randInitializeWeights(input_layer_size, hidden_layer_size);
            initial_Theta2 = randInitializeWeights(hidden_layer_size, num_labels);

            initial_nn_params = [initial_Theta1(:) ; initial_Theta2(:)];

            fprintf('\nChecking Backpropagation... \n');

            %  Change the MaxIter to a larger
            %  value to see how more training helps.
            options = optimset('MaxIter', 100);

            lambda = 0.5;
            % checkNNGradients(lambda);

            fprintf('\nChecking Cost Function \n')

            % Create "short hand" for the cost function to be minimized
            costFunction = @(p) nnCostFunction(p, ...
                                               input_layer_size, ...
                                               hidden_layer_size, ...
                                               num_labels, X, y, lambda);

            % Now, costFunction is a function that takes in only one argument (the
            % neural network parameters)
            [nn_params, cost] = fmincg(costFunction, initial_nn_params, options);

            % Obtain Theta1 and Theta2 back from nn_params
            Theta1 = reshape(nn_params(1:hidden_layer_size * (input_layer_size + 1)), ...
                             hidden_layer_size, (input_layer_size + 1));

            Theta2 = reshape(nn_params((1 + (hidden_layer_size * (input_layer_size + 1))):end), ...
                             num_labels, (hidden_layer_size + 1));

            fprintf('Cost: %f ', cost);
            [signal, confidence] = predict(Theta1, Theta2, X);
            fprintf('\nTraining Set Accuracy: %f\n', mean(double(signal == y)) * 100);
        end
        
        %% Experiment
        function experiment(obj)
            Xval = dlmread([directory, '/cross-validation_x.csv'], ',', 1, 1);
            fid = fopen([directory, '/cross-validation_y.csv']);
            exp=textscan(fid, '%d %f %f %f %f %s', 'HeaderLines', 1, 'Delimiter', ',');
            fclose(fid);
            yval = exp{2};

            [pred_val, confidence_val] = predict(Theta1, Theta2, Xval);

            fprintf('\nCrossvalidation Set Accuracy: %f\n', mean(double(pred_val == yval)) * 100);

            if ~exist([directory, '/result'], 'dir')
                mkdir([directory, '/result']);
            end
            csvwrite([directory, '/result/Theta1.csv'],Theta1);
            csvwrite([directory, '/result/Theta2.csv'],Theta2);



            pause;



            experiment(X,y,Xval, yval, input_layer_size, ...
                                hidden_layer_size, num_labels, ...
                                initial_nn_params, lambda);
        end
    end
    methods(Static)
        function tu = sqlite2unix(tm)
            tu = round(86400 * (datenum(tm, 'yyyy-mm-dd HH:MM') - datenum('1970', 'yyyy')));
        end
        function tm = unix2sqlite(tu)
            tm = datestr(datenum('1970', 'yyyy') + tu / 86400, 'yyyy-mm-dd HH:MM');
        end
    end
    
end

