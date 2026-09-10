function [contour, Squelette_X, Squelette_Y, Adjacence, Rayons] = calcul_squelette_voronoi(masque_courant, pas)


    [r_deb, c_deb] = find(masque_courant, 1, 'first');
    contour = bwtraceboundary(masque_courant, [r_deb, c_deb], 'S');
    
    X_bord = contour(1:pas:end, 2); Y_bord = contour(1:pas:end, 1); 
    P_bord = [X_bord, Y_bord];
    % On supprime les points doublons pour éviter que voronoin ne panique
    P_bord = unique(P_bord, 'rows', 'stable');
    [V, C] = voronoin(P_bord);
    V(1, :) = []; 
    
    points_internes = inpolygon(V(:,1), V(:,2), X_bord, Y_bord);
    Squelette_X = V(points_internes, 1);
    Squelette_Y = V(points_internes, 2);
    
    idx_proche = dsearchn(P_bord, [Squelette_X Squelette_Y]);
    Rayons = sqrt((P_bord(idx_proche,1) - Squelette_X).^2 + (P_bord(idx_proche,2) - Squelette_Y).^2);
    
    num_V = size(V, 1) + 1; % +1 car on a enlevé l'infini
    Adj_globale = zeros(num_V, num_V);
    for c_idx = 1:length(C)
        cellule = C{c_idx}; 
        for j = 1:length(cellule)
            idx1 = cellule(j);
            if j < length(cellule), idx2 = cellule(j+1); else, idx2 = cellule(1); end
            if idx1 ~= 1 && idx2 ~= 1
                Adj_globale(idx1, idx2) = 1; Adj_globale(idx2, idx1) = 1;
            end
        end
    end
    Adj_globale(1, :) = []; Adj_globale(:, 1) = [];
    Adjacence = Adj_globale(points_internes, points_internes);
    