function cord = cordic(angle)
    % x and y initialization (x will be cosine result and y will be sine
    % result of the input angle
    x = 0.6072529350088814;
    y = 0;

    % z store the delta between 2 successive iteration
    % sometimes people check if this z lies below the threshold to break
    % the loop but it seems to be not precise in case we calculate the
    % value of the angle that is in the LUT already -> just run 32 stages
    % to get the final stage for the high precision
    z = angle;
    % threshold = 0.0000001;

    % d will have 2 values only {-1;1} based on the rotating direction
    d=0;

    % convert the angle to be minus angle in case they are bigger than pi
    if(z > pi)
        z = z - 2*pi;
    end

    % cordic algorithm is only used for the range of angles [-pi/2;pi/2]
    % so we need to pre-rotate the angle back to this quadrant 1 and 4 if
    % it lied in the 2nd and 3rd quadrant
    if(z > pi/2 && z <= pi)                 % 2nd quadrant
        z = z - pi;
        x = -x;
        y = -y;
    elseif (z < -pi/2 && z >= -pi)          % 3rd quadrant
        x = -x;
        y = -y;
        z = z + pi;
    end
    
    % print angle after processing to check (only for test)
    fprintf("Angle: %f\n", z);
    
    % iterate 32 times for 32 bits
    for iter = 0:31
        if(z <= 0)
            d = -1;
        else
            d = 1;
        end
        
        % formula to calculate new x, y and z value
        newx = x - (y * d * 2.0^(-iter));
        newy = y + (x * d * 2.0^(-iter));
        x = newx;
        y = newy;
        z = z - (d * atan(2^(-iter)));
    end

    % log output
    fprintf("cosine: %f\n",x);
    fprintf("z: %f\n",z);
    fprintf("sine: %f\n",y);