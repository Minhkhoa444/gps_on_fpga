function a = NewtonRaphson(x,y,z,d)
    tol = 0.0001;
    a = [1; 1; 1; 1];
    iter_max = 15;
    n = length(x);
    jacobian = [0, 0, 0, 0; 
                0, 0, 0, 0; 
                0, 0, 0, 0; 
                0, 0, 0, 0];    % Jacobian matrix
    b = [0; 0; 0; 0; 0];
    for i = 1:n
        jacobian(i,4) = -299792458;
    end

    for iter = 1:iter_max    % Loop to limitation
        prev_x = a(1);
        for i = 1:n          % Loop to calculate Jacobian values (derivatives)
                jacobian(i,1) = -(a(1) - x(i))/sqrt((a(1)-x(i))^2 + (a(2)-y(i))^2 + (a(3)-z(i))^2);
                jacobian(i,2) = -(a(2) - y(i))/sqrt((a(1)-x(i))^2 + (a(2)-y(i))^2 + (a(3)-z(i))^2);
                jacobian(i,3) = -(a(3) - z(i))/sqrt((a(1)-x(i))^2 + (a(2)-y(i))^2 + (a(3)-z(i))^2);

                b(i) = -(d(i) - sqrt((a(1)-x(i))^2 + (a(2)-y(i))^2 + (a(3)-z(i))^2) - 299792458*a(4));
        end
        jacobian_tranpose = transpose(jacobian);

        left = jacobian_tranpose*jacobian;
        right = jacobian_tranpose*b;
        delta = inv(left)*right;        % Change in 2 sucessive iteration

        a = a + delta;                  % New value
        if(abs((a(1)-prev_x)/a(1)) * 100 < tol)    % Exit loop whenever the rate of change is under threshold
            break;
        end
    end

    fprintf("This is user's location: x(%f) - y(%f) - z(%f)\n",a(1), a(2), a(3));                 % User's Location
    fprintf("Timing offset: %f ", a(4));
