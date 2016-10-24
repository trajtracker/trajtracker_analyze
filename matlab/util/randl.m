% Return random variable(s) with linear distribution within [0,1] and 
% 0 outside; m specifies the slope
%
% In other word
% P(x)= mx+b if 0<=x<=1
% P(x)= 0    otherwise
%
% where b=1-m/2 as int P(x) should be 1
%
% Usage: ran=randl(m,SIZE)
%
% E.g. X=randl(1,[20,20])
% X is matrix with size [20,20] and with distribution
% p(x)=x+0.5 if 0<=x<=1 and p(x)=0 otherwise
%
% Written by Samuel Cheng, Copyright 2005
%
% You are allowed to redistribute or use the code if this mfile is unchanged.

function ran=randl(m,SIZE)

if exist('m')~=1
    error('Please specified m. Help randl for more info');
end
if abs(m)>2
    error('abs(m) need to be smaller than 2');
end

if exist('SIZE')~=1
    SIZE=1;
end

if m>=0
 randb=rand(SIZE)>(m/2);
 ran=randb.*rand(SIZE) + (1-randb).*randtri(SIZE);
else
 m=-m;
 randb=rand(SIZE)>(m/2);
 ran=randb.*rand(SIZE) + (1-randb).*randtri(SIZE);
 ran=1-ran;
end
  

% triangle rand function
function randtri=randtri(SIZE)

randtri=rand(SIZE)+rand(SIZE);
randtri(randtri>1)=2-randtri(randtri>1);