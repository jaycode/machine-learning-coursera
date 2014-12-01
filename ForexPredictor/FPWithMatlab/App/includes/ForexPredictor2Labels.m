classdef ForexPredictor2Labels < ForexPredictor
    % ForexPredictor class for two labels
    properties (SetAccess = protected)
        num_labels = 2;
    end
    %% Public methods:
    methods
        function fp = ForexPredictor3Labels(input_dbname, tableset_name, prediction_days)
            fp@ForexPredictor(input_dbname, tableset_name, prediction_days)
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
            
            filter = ForexPredictor.getInputsFilter();
            
            sql_create = strcat('CREATE TABLE IF NOT EXISTS', {' `'}, obj.tableset_name,'_',obj.y_table_name, '`(', create_fields_text, ', UNIQUE(time))');
            mksqlite(sql_create{1});
            sql = strcat('INSERT OR IGNORE INTO `',obj.tableset_name,'_',obj.y_table_name,'` ( ',fields_text,' ) ', ...
                ' SELECT y.time, 1 as signal, bids, asks, maxclose, uppertarget FROM `', ...
                obj.tableset_name,'_',targets_table_name,'` y, `',obj.tableset_name,'_',inputs_table_name,'` x', ...
                ' WHERE uppertarget >= ? AND x.time = y.time AND ', ...
                filter, ...
                ' ORDER BY y.time DESC LIMIT ?');
            mksqlite(sql, upper_t, limit);

            % Select n% threshold targets for sell signals.
            sql = strcat('INSERT OR IGNORE INTO `',obj.tableset_name,'_',obj.y_table_name,'` ( ',fields_text,' ) ', ...
                'SELECT y.time, 0 as signal, bids, asks, minclose, lowertarget FROM `', ...
                obj.tableset_name,'_',targets_table_name,'` y, `',obj.tableset_name,'_',inputs_table_name,'` x', ...
                ' WHERE lowertarget <= ? AND uppertarget < ? AND x.time = y.time AND', ...
                filter, ...
                ' ORDER BY y.time DESC LIMIT ?');
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
    end
    
end

