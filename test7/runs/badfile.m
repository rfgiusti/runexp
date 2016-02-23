function outer
inner;
end

function inner
accessory;
end

function accessory
f = fopen('/XAadfYIosijG/this file should not be writeabble', 'r');
fprintf('Reading from file: %s\n', fscanf(f, '%s');
fclose(f);
fprintf('RES:done WHHAAAAAT?\n');
end
