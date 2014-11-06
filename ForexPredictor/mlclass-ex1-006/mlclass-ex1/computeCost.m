function J = computeCost(X, y, theta)
%COMPUTECOST Compute cost for linear regression
%   J = COMPUTECOST(X, y, theta) computes the cost of using theta as the
%   parameter for linear regression to fit the data points in X and y

% Initialize some useful values
m = length(y); % number of training examples

% You need to return the following variables correctly 
J = 0;

% ====================== YOUR CODE HERE ======================
% Instructions: Compute the cost of a particular choice of theta
%               You should set J to the cost.

% my first answer:
% J = 1/(2*(length(X)))* sum((X*theta-y).^2);
% answer from hint (might be faster since no sum is involved):
% J = 1/(2*m)* (X*theta-y)'*(X*theta-y);
% loop style
for i = 1:length(X)
  J = J + (1/(2*m) * ( (X(i,1) * theta(1) + X(i,2) * theta(2)) - y(i))^2);
end

% =========================================================================

end
