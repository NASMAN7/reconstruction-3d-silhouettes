function masque_courant = binariser_dino_lab(germes_color_lab, labels)
 a_vals = germes_color_lab(:, 2);
 b_vals = germes_color_lab(:, 3);        
        
 mask_sp = (a_vals > 2) & (b_vals > 2);
        
 masque_courant = mask_sp(labels);

 
 masque_courant = bwareafilt(logical(masque_courant), 1);
 masque_courant = imclose(masque_courant, strel('disk', 5));
 masque_courant = imfill(masque_courant, 'holes'); % Astuce pour boucher les trous