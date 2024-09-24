function a = GaussNewton(x,y,z,d)
    tol = 1;
    a = [1; 1; 1; 1];
    iter_max = 10;
    n = length(x);
    jacobian = [0, 0, 0, 0; 
                0, 0, 0, 0; 
                0, 0, 0, 0; 
                0, 0, 0, 0];
    b = [0; 0; 0; 0; 0];
    for i = 1:n
        jacobian(i,4) = -299792458;
    end

    for iter = 1:iter_max
        prev_x = a(1);
        for i = 1:n
                jacobian(i,1) = -(a(1) - x(i))/sqrt((a(1)-x(i))^2 + (a(2)-y(i))^2 + (a(3)-z(i))^2);
                jacobian(i,2) = -(a(2) - y(i))/sqrt((a(1)-x(i))^2 + (a(2)-y(i))^2 + (a(3)-z(i))^2);
                jacobian(i,3) = -(a(3) - z(i))/sqrt((a(1)-x(i))^2 + (a(2)-y(i))^2 + (a(3)-z(i))^2);

                b(i) = -(d(i) - sqrt((a(1)-x(i))^2 + (a(2)-y(i))^2 + (a(3)-z(i))^2) - 299792458*a(4));
        end
        jacobian_tranpose = transpose(jacobian);

        left = jacobian_tranpose*jacobian;
        right = jacobian_tranpose*b;
        delta = inv(left)*right;
        % fprintf(' %f ', left);


        a = a + delta;
        if(abs((a(1)-prev_x)/a(1)) * 100 < tol)
            break;
        end
    end

    fprintf(' %d ',size(delta));
    fprintf(' %f ',a);