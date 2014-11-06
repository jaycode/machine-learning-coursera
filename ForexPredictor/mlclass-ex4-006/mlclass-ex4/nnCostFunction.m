function [J grad] = nnCostFunction(nn_params, ...
                                   input_layer_size, ...
                                   hidden_layer_size, ...
                                   num_labels, ...
                                   X, y, lambda)
%NNCOSTFUNCTION Implements the neural network cost function for a two layer
%neural network which performs classification
%   [J grad] = NNCOSTFUNCTON(nn_params, hidden_layer_size, num_labels, ...
%   X, y, lambda) computes the cost and gradient of the neural network. The
%   parameters for the neural network are "unrolled" into the vector
%   nn_params and need to be converted back into the weight matrices. 
% 
%   The returned parameter grad should be a "unrolled" vector of the
%   partial derivatives of the neural network.
%

% Reshape nn_params back into the parameters Theta1 and Theta2, the weight matrices
% for our 2 layer neural network
Theta1 = reshape(nn_params(1:hidden_layer_size * (input_layer_size + 1)), ...
                 hidden_layer_size, (input_layer_size + 1));

Theta2 = reshape(nn_params((1 + (hidden_layer_size * (input_layer_size + 1))):end), ...
                 num_labels, (hidden_layer_size + 1));

% Setup some useful variables
m = size(X, 1);
         
% You need to return the following variables correctly 
J = 0;
Theta1_grad = zeros(size(Theta1));
Theta2_grad = zeros(size(Theta2));

% ====================== YOUR CODE HERE ======================
% Instructions: You should complete the code by working through the
%               following parts.
%
% Part 1: Feedforward the neural network and return the cost in the
%         variable J. After implementing Part 1, you can verify that your
%         cost function computation is correct by verifying the cost
%         computed in ex4.m
%
% Part 2: Implement the backpropagation algorithm to compute the gradients
%         Theta1_grad and Theta2_grad. You should return the partial derivatives of
%         the cost function with respect to Theta1 and Theta2 in Theta1_grad and
%         Theta2_grad, respectively. After implementing Part 2, you can check
%         that your implementation is correct by running checkNNGradients
%
%         Note: The vector y passed into the function is a vector of labels
%               containing values from 1..K. You need to map this vector into a 
%               binary vector of 1's and 0's to be used with the neural network
%               cost function.
%
%         Hint: We recommend implementing backpropagation using a for-loop
%               over the training examples if you are implementing it for the 
%               first time.
%
% Part 3: Implement regularization with the cost function and gradients.
%
%         Hint: You can implement this around the code for
%               backpropagation. That is, you can compute the gradients for
%               the regularization separately and then add them to Theta1_grad
%               and Theta2_grad from Part 2.
%

% ==================================
% FEEDFORWARD
% ==================================

num_hidden_layers = 1;
A = {[ones(size(X,1), 1) X]};
Z = {};
Thetas = {Theta1; Theta2};
layer_sizes = {input_layer_size; hidden_layer_size; num_labels};
reg = 0;

for i = 1:(num_hidden_layers+1)
  % A{i+1} = [ones(m, layer_sizes{i+1})];
  Z{i+1} = A{i} * Thetas{i}';
  A{i+1} = sigmoid(Z{i+1});
  if lambda > 0
    reg = reg + sum(sum(Thetas{i}(:,2:end).^2));
  end
  % do not add on last a.
  if i <= num_hidden_layers
    A{i+1} = [ones(size(A{i+1},1), 1) A{i+1}];
  end
end

reg = lambda / (2 * m) * reg;

Beta = 0;

% ==================================
% CONVERTING NUMBERS TO POSITONS
% ==================================
% y_matrix = zeros(m, num_labels);
% for i = 1:m
%   y_matrix(i, y(i)) = 1;
% end
% That above is the same with:
y_matrix = eye(num_labels)(y,:);

% ==================================
% COST FUNCTION
% ==================================

% for i = 1:m
%   for k = 1:num_labels
%     Beta = Beta + (-y_matrix(i, k) * log(A{end}(i,k))) - (1 - y_matrix(i, k)) * log(1 - A{end}(i,k));
%   end
% end
% J = 1/m * Beta;

% Good, now can we vectorize it?
% for i = 1:m
%   % Beta = Beta + sum(sum(-y_matrix(i,:) .* log(A{end}(i,:)) - ( (1-y_matrix(i,:)) .* log(1-A{end}(i,:)))));
%   % To avoid sums, we multiply with vector of 1's
%   Beta = Beta + (-y_matrix(i,:) .* log(A{end}(i,:)) - ( (1-y_matrix(i,:)) .* log(1-A{end}(i,:)))) * ones(num_labels, 1);
% end
% J = 1/m * Beta;

% Awesome! Turns out for y vs log(A{end}) we need element multiplication! (.* instead of *)
% Wondering if we can solve this without loop at all?
J = 1/m *sum( sum( ( -y_matrix .* log(A{end}) ) - ( (1.-y_matrix) .* log(1-A{end}) )) );

% Or without sum, but we ended up with longer code so lets not use it.
% J = 1/m * (( ( -y_matrix .* log(A{end}) ) - ( (1.-y_matrix) .* log(1-A{end}) )) * ones(num_labels, 1))' * ones(m, 1);

J = J + reg;

% ==================================
% BACK PROPAGATION
% ==================================

% Correct implementation with for loop.

% Deltas = cell(numel(Thetas));

% for t = 1:m
%   d_temp = {};
%   d_temp{numel(A)} = (A{end}(t,:) - y_matrix(t,:))';
%   a_temp = A{end-1}(t,:)';
%   Delta_temp = d_temp{numel(Thetas)+1} * a_temp';
%   if (size(Deltas{numel(Thetas)}) == 0)
%     Deltas{numel(Thetas)} = Delta_temp;
%   else
%     Deltas{numel(Thetas)} += Delta_temp;
%   end

%   for i = 2:(numel(A)-1)
%     j = numel(A) - (i-1);
%     d_temp{j} = zeros(layer_sizes{j}, 1);
%     z_temp = Z{j}(t,:)';
%     z_grad = sigmoidGradient(z_temp);
%     Theta = Thetas{j}(:,2:end);
%     % Theta = Thetas{j};
%     d_temp{j} = (Theta' * d_temp{j+1}).*(z_grad);
%     a_temp = A{j-1}(t,:)';
%     keyboard;
%     Delta_temp = d_temp{j} * a_temp';
%     if (size(Deltas{j-1}) == 0)
%       Deltas{j-1} = Delta_temp;
%     else
%       Deltas{j-1} += Delta_temp;
%     end
%   end
% end
% Theta1_grad = (1/m) .* Deltas{1};
% Theta2_grad = (1/m) .* Deltas{2};


% Can we vectorize it?

Deltas = cell(numel(Thetas));

d_temp = {};
d_temp{numel(A)} = (A{end} - y_matrix)';
a_temp = A{end-1};
Delta_temp = d_temp{numel(A)} * a_temp;
Deltas{numel(Thetas)} = Delta_temp;

for i = 2:(numel(A)-1)
  j = numel(A) - (i-1);
  z_temp = Z{j}';
  z_grad = sigmoidGradient(z_temp);
  Theta = Thetas{j}(:,2:end);
  d_temp{j} = (d_temp{j+1}' * Theta ).*(z_grad)';
  a_temp = A{j-1}';
  Delta_temp = (a_temp * d_temp{j})';
  if (size(Deltas{j-1}) == 0)
    Deltas{j-1} = Delta_temp;
  else
    Deltas{j-1} += Delta_temp;
  end
end

Theta1_grad = (1/m) .* Deltas{1};
Theta2_grad = (1/m) .* Deltas{2};

% ==================================
% REGULARIZED NEURAL NETWORKS
% ==================================
Reg = cell(numel(Thetas));
for i = 1:numel(Thetas)
  Reg{i} = (lambda/m)*Thetas{i};
  Reg{i}(:,1) = 0;
end

Theta1_grad = Theta1_grad + Reg{1};
Theta2_grad = Theta2_grad + Reg{2};


% -------------------------------------------------------------

% =========================================================================

% Unroll gradients
grad = [Theta1_grad(:) ; Theta2_grad(:)];


end
