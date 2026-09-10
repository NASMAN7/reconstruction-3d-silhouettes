function [germes_color, labels, germes_x, germes_y, num_germes] = calcul_superpixels_slic(img_rgb, K, max_iter, m, Seuil)
    
    img_rgb = double(img_rgb);
    % On garde une copie RGB pour l'affichage, mais on calcule en LAB
    img_lab = rgb2lab(uint8(img_rgb)); 
    
    [rows, cols, ~] = size(img_lab);
    S = round(sqrt((rows * cols) / K));      
    
    % --- INITIALISATION ---
    x_grid = S/2 : S : cols; y_grid = S/2 : S : rows;
    [X_grid, Y_grid] = meshgrid(x_grid, y_grid);
    germes_x = X_grid(:); germes_y = Y_grid(:);
    num_germes = length(germes_x);
    
    % On stocke les couleurs moyennes en LAB
    germes_color = zeros(num_germes, 3);
    for k= 1:num_germes 
        germes_color(k,:) = img_lab(round(germes_y(k)), round(germes_x(k)), :);
    end
    
    labels = -1 * ones(rows, cols);
    distances = inf(rows, cols);
    
    % Canaux LAB pour la rapidité
    L_img = img_lab(:,:,1); A_img = img_lab(:,:,2); B_img = img_lab(:,:,3);

    % --- BOUCLE SLIC ---
    for iter = 1:max_iter
        distances(:) = inf;
        old_germes_x = germes_x; old_germes_y = germes_y;
        
        for k = 1:num_germes
            % Zone locale 2S x 2S
            r_min = max(1, floor(germes_y(k) - S)); r_max = min(rows, ceil(germes_y(k) + S));
            c_min = max(1, floor(germes_x(k) - S)); c_max = min(cols, ceil(germes_x(k) + S));
            
            % --- CALCUL VECTORISÉ ---
            L_sub = L_img(r_min:r_max, c_min:c_max);
            A_sub = A_img(r_min:r_max, c_min:c_max);
            B_sub = B_img(r_min:r_max, c_min:c_max);
            
            % Distance couleur (LAB)
            d_color = (L_sub - germes_color(k,1)).^2 + ...
                      (A_sub - germes_color(k,2)).^2 + ...
                      (B_sub - germes_color(k,3)).^2;
            
            % Distance spatiale
            [cc, rr] = meshgrid(c_min:c_max, r_min:r_max);
            d_spatial = (rr - germes_y(k)).^2 + (cc - germes_x(k)).^2;
            
            % Distance SLIC 
            Ds = sqrt(d_color + (m/S)^2 * d_spatial);
            
            % Mise à jour locale
            local_dist = distances(r_min:r_max, c_min:c_max);
            mask = Ds < local_dist;
            
            local_dist(mask) = Ds(mask);
            distances(r_min:r_max, c_min:c_max) = local_dist;
            
            local_labels = labels(r_min:r_max, c_min:c_max);
            local_labels(mask) = k;
            labels(r_min:r_max, c_min:c_max) = local_labels;
        end
    
        % Mise à jour des centres
        for k = 1:num_germes
            mask_k = (labels == k);
            if any(mask_k(:))
                [r_idx, c_idx] = find(mask_k);
                germes_y(k) = mean(r_idx);
                germes_x(k) = mean(c_idx);
                % Moyenne des couleurs en LAB
                germes_color(k, :) = [mean(L_img(mask_k)), mean(A_img(mask_k)), mean(B_img(mask_k))];
            end
        end
        
        % --- AFFICHAGE ---
        %figure(1); clf;
        %subplot(1, 2, 1);
        %imagesc(uint8(img_rgb)); hold on; % On affiche le RGB original !
        %plot(germes_x, germes_y, 'y+', 'MarkerSize', 6);
        %title(sprintf('Itération %d', iter)); axis off;
        
        %subplot(1, 2, 2);
        % On affiche les frontières pour bien voir si c'est compact
        %imshow(imoverlay(uint8(img_rgb), boundarymask(labels), 'r'));
        %title('Frontières Superpixels'); axis off;
        
        %drawnow;

        % Condition d'arrêt
        E = sum(sqrt((germes_x - old_germes_x).^2 + (germes_y - old_germes_y).^2));
        if E < Seuil, break; end
    end
end