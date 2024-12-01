function ca = ca_generator()
    % Initialize all 1s
    G1 = [1;1;1;1;1;1;1;1;1;1];
    G2 = [1;1;1;1;1;1;1;1;1;1];
    output = zeros(32,1023);

    % Code Phase Selection
    tab = [
            2,6;    %1
            3,7;    %2
            4,8;    %3
            5,9;    %4
            1,9;    %5
            2,10;   %6
            1,8;    %7
            2,9;    %8
            3,10;   %9
            2,3;    %10
            3,4;    %11
            5,6;    %12
            6,7;    %13
            7,8;    %14
            8,9;    %15
            9,10;   %16
            1,4;    %17
            2,5;    %18
            3,6;    %19
            4,7;    %20
            5,8;    %21
            6,9;    %22
            1,3;    %23
            4,6;    %24
            5,7;    %25
            6,8;    %26
            7,9;    %27
            8,10;   %28
            1,6;    %29
            2,7;    %30
            3,8;    %31
            4,9;    %32
    ];

    for prn_ids = 1:32
        for iter = 0:1022
            % Output process
            output(prn_ids,iter+1) = xor(G1(10),xor(G2(tab(prn_ids,1)),G2(tab(prn_ids,2))));
    
            % G1 process
            new_bit = xor(G1(10), G1(3));   % calculate new bit
            G1 = circshift(G1,1);           % shift right G1
            G1(1) = new_bit;                % inser new bit to the leftmost position
            
            % G2 process
            new_bit = xor(G2(10), xor(G2(9), xor(G2(8), xor(G2(6), xor(G2(3),G2(2))))));
            G2 = circshift(G2,1);
            G2(1) = new_bit;
            
        end

        % Reset G1 and G2
        G1 = [1;1;1;1;1;1;1;1;1;1];
        G2 = [1;1;1;1;1;1;1;1;1;1];
    end

    % Verify results
    for prn_ids = 1:32
        ca_code = gnssCACode(prn_ids, "GPS");
        result = isequal(output(prn_ids,:)', ca_code);
        if (result == 0) 
            fprintf("FAILED!\n");
            fprintf("%d\n",prn_ids);
            break;
        elseif (prn_ids == 32)
            fprintf("SUCCESS!\n");
        end
    end