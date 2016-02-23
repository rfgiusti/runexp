function outer
inner;
end

function inner
accessory;
end

function accessory
error('accessory() throws an error. Does it show a stack trace?');
end
