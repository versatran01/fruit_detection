function obs = generateObesrvationCs()

ds = Dataset('/home/chao/Dropbox/agriculture_state_of_art/Datasets/booth/booth_combined');
obs = extractObservations(ds, @rgb2fullcs);
end

