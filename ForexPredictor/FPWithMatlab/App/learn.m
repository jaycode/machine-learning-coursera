function output = learn(tableset_name)
    % Initialization
    addpath('mksqlite');
    addpath('includes');
    close all; clc
    mksqlite('open','forex_predictor.db');

    % Setup the parameters
    input_layer_size  = 13;
    hidden_layer_size = 4;
    num_labels = 2;
    directory = 't0.5n5';

    fprintf('\nLoading training data ...\n')

    data = mksqlite(['SELECT * FROM `', tableset_name, '_x`']);
    fields = fieldnames(data);
    caller = '';
    for i=3:size(fields,1)
        caller = [caller, ' x.', fields{i}];
    end
    caller = sprintf('cell2mat(arrayfun(@(x) [%s], data, ''UniformOutput'', false))', caller);
    X = eval(caller);
        
    data = mksqlite(['SELECT signal FROM `', tableset_name, '_y`']);
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

    [pred, confidence] = predict(Theta1, Theta2, X);

    fprintf('\nTraining Set Accuracy: %f\n', mean(double(pred == y)) * 100);

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

    output = 1;
end