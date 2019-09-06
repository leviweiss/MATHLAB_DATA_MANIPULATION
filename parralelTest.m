% first();
% second();

parpool(1);
MyCode(200);

function a = MyCode(A)
tic
parfor i = 1:200
    a(i) = max(abs(eig(rand(A))));
end
toc
end

function first()
tic
n = 120;
A = 200;
a = zeros(1,n);
for i = 1:n
    a(i) = max(abs(eig(rand(A))));
end
disp('first')
toc
end

function second()
tic
n = 120;
A = 200;
a = zeros(1,n);
parfor i = 1:n
    a(i) = max(abs(eig(rand(A))));
end
disp('second')
toc
end

