function experiment(X,y,Xval, yval, input_layer_size, ...
                    hidden_layer_size, num_labels, ...
                    initial_nn_params, lambda)

% Experiment with learning curves.

% number of iterations

figure(2);
iter_start = 99;
iter_end = 100;
[error_train] = ...
    learningCurveIter(input_layer_size, hidden_layer_size, ...
                  num_labels, ...
                  initial_nn_params, X, y, lambda, ...
                  iter_start, iter_end);
plot(1:(iter_end-iter_start), error_train);

title(sprintf('ANN Learning Curve (lambda = %f)', lambda));
xlabel('Number of iterations')
ylabel('Accuracy')
axis([iter_start iter_end 0 100])
legend('Train')

fprintf('ANN (lambda = %f)\n\n', lambda);
fprintf('# Number of iterations \tTrain Accuracy\n');
for i = 1:(iter_end-iter_start)
    fprintf('  \t%d\t\t%f\t%f\n', (i+iter_start-1), error_train(i));
end;

% number of training examples

m = size(X, 1);
iter = 50;
figure(2);
[error_train, error_val] = ...
    learningCurve(input_layer_size, hidden_layer_size, ...
                  num_labels, ...
                  initial_nn_params, X, y, Xval, yval, lambda, ...
                  iter);
plot(1:m, error_train, 1:m, error_val);

title(sprintf('ANN Learning Curve (lambda = %f)', lambda));
xlabel('Number of training examples')
ylabel('Accuracy')
axis([1 m 0 100])
legend('Train', 'Cross Validation')

fprintf('ANN (lambda = %f)\n\n', lambda);
fprintf('# Training Examples\tTrain Accuracy\tCross Validation Accuracy\n');
for i = 1:m
    fprintf('  \t%d\t\t%f\t%f\n', i, error_train(i), error_val(i));
end;

fprintf('Program paused. Press enter to continue.\n');
pause;

end