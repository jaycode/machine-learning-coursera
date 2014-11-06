%% Initialization
clear ; close all; clc

%% Setup the parameters
input_layer_size  = 13;
hidden_layer_size = 4;
num_labels = 2;
directory = 't0.2n5';

fprintf('\nLoading training data ...\n')

X = dlmread([directory, '/training_x.csv'], SEP=',', R0=1, C0=0);
Y = dlmread([directory, '/training_y.csv'], SEP=',', R0=1, C0=0);
y = Y(:,1);

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

fprintf(['Cost: %f '], cost);

[pred, confidence] = predict(Theta1, Theta2, X);

fprintf('\nTraining Set Accuracy: %f\n', mean(double(pred == y)) * 100);

Xval = dlmread([directory, '/cross-validation_x.csv'], SEP=',', R0=1, C0=0);
Yval = dlmread([directory, '/cross-validation_y.csv'], SEP=',', R0=1, C0=0);
yval = Yval(:,1);

[pred_val, confidence_val] = predict(Theta1, Theta2, Xval);

fprintf('\nCrossvalidation Set Accuracy: %f\n', mean(double(pred_val == yval)) * 100);

mkdir([directory, '/result']);
csvwrite([directory, '/result/Theta1.csv'],Theta1);
csvwrite([directory, '/result/Theta2.csv'],Theta2);



pause;



experiment(X,y,Xval, yval, input_layer_size, ...
                    hidden_layer_size, num_labels, ...
                    initial_nn_params, lambda);