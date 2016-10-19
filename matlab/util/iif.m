function result = iif(cond, t, f)
%IIF - Conditional function that returns T or F, depending of condition COND
%
%  Detailed 
%     Conditional matrix or scalar double function that returns a matrix
%     of same size than COND, with T or F depending of COND boolean evaluation
%     if T or/and F has the same dimensions than COND, it uses the  corresponding 
%     element in the assignment
%     if COND is scalar, returns T or F in according with COND evaluation, 
%     even if T or F is matrices like char array.
%
%  Syntax
%    Result = iif(COND, T, F)
%           COND - Matrix or scalar condition
%           T  - expression if COND is true
%           F  - expression if COND is false
%           Result - Matrix or scalar of same dimensions than COND, containing T
%                    if COND element is true or F if COND element is false.
%
    if isscalar(cond) 
       if cond 
           result = t;
       else
           result = f;
       end
    else
      result = (cond).*t + (~cond).*f;
    end

end
