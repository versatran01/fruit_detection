function model_names = getAllModelNames(model_directory)
model_names = {};
listings = dir(model_directory);
k = 1;
for i = 1:numel(listings)
    listing = listings(i);
    if ~listing.isdir
        if ~isempty(strfind(listing.name, '.mat'))
            model_names{k} = listing.name;
            k = k + 1;
        end
    end
end