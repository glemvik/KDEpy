function [pdf,grid]=akde1d(X,grid,gam)
%% fast adaptive kernel density estimation in one-dimension;
%  provides optimal accuracy/speed tradeoff, controlled with parameter "gam";
% INPUTS:   X  - data as a 'n' by '1' vector;
%
%         grid - (optional) mesh over which density is to be computed;
%                default mesh uses 2^12 points over range of data;
%
%          gam - (optional) cost/accuracy tradeoff parameter, where gam<n;
%                default value is gam=ceil(n^(1/3))+20; larger values
%                may result in better accuracy, but always reduce speed;
%                to speedup the code, reduce the value of "gam"; 
%
% OUTPUT: pdf - the value of the estimated density at 'grid'
%
%%  EXAMPLE:
%   data=[exp(randn(10^3,1))]; % log-normal sample
%   [pdf,grid]=akde1d(data); plot(grid,pdf)
%
% Note: If you need a very fast estimator use my "kde.m" function.
% This routine is more adaptive at the expense of speed. Use "gam"
% to control a speed/accuracy tradeoff. 
%
%%  Reference:
%  Kernel density estimation via diffusion
%  Z. I. Botev, J. F. Grotowski, and D. P. Kroese (2010)
%  Annals of Statistics, Volume 38, Number 5, pages 2916-2957.
[n, d] = size(X);

% begin scaling preprocessing
MAX=max(X,[],1);
MIN=min(X,[],1);
scaling=MAX-MIN;
MAX=MAX+scaling/10;
MIN=MIN-scaling/10;
scaling=MAX-MIN;
X=bsxfun(@minus,X,MIN)
;X=bsxfun(@rdivide,X,scaling);
if (nargin<2)||isempty(grid) % failing to provide grid
    grid=(MIN:scaling/(2^12-1):MAX)';
end

mesh=bsxfun(@minus,grid,MIN);
mesh=bsxfun(@rdivide,mesh,scaling);
if nargin<3 % failing to provide speed/accuracy tradeoff
    gam=ceil(n^(1/3))+20;
end
% end preprocessing

% algorithm initialization
del=.2/n^(d/(d+4));
perm=randperm(n);
mu=X(perm(1:gam),:);
w=rand(1,gam);
w=w/sum(w);
Sig=del^2*rand(gam,d);
ent=-Inf;
for iter=1:1500 % begin algorithm
    Eold=ent;
    [w,mu,Sig,del,ent]=regEM(w,mu,Sig,del,X); % update parameters
    err=abs((ent-Eold)/ent); % stopping condition
    fprintf('Iter.    Tol.      Bandwidth \n');
    fprintf('%4i    %8.2e   %8.2e\n',iter,err,del);
    fprintf('----------------------------\n');
    if (err<10^-5)|iter>200, break, end
end
% now output density values at grid
pdf = probfun(mesh,w,mu,Sig)/prod(scaling); % evaluate density
del=del*scaling; % adjust bandwidth for scaling
end

