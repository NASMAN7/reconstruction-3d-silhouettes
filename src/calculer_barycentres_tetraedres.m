function C_g = calculer_barycentres_tetraedres(X, tri)
%CALCULER_BARYCENTRES_TETRAEDRES Echantillonne chaque tetraedre en 5 points.
%
%   C_g = CALCULER_BARYCENTRES_TETRAEDRES(X, tri) calcule, pour chaque
%   tetraedre defini par les indices de sommets TRI (une ligne = un
%   tetraedre), 5 barycentres ponderes de ses 4 sommets : le barycentre
%   uniforme, puis 4 barycentres decentres (70%) vers chacun des sommets.
%   Cet echantillonnage permet de tester la coherence d'un tetraedre avec
%   les silhouettes en plusieurs points de son volume plutot qu'en son seul
%   centre de gravite.
%
%   Entrees :
%       X   : 3 x nb_points (ou 4 x nb_points homogene) - nuage de points 3D
%       tri : nb_tetra x 4 - indices des sommets de chaque tetraedre
%
%   Sortie :
%       C_g : 4 x nb_tetra x 5 - coordonnees homogenes [X;Y;Z;1] des 5
%             barycentres de chaque tetraedre

    poids = [0.25, 0.25, 0.25, 0.25;   % barycentre uniforme
             0.70, 0.10, 0.10, 0.10;   % decentre vers le sommet 1
             0.10, 0.70, 0.10, 0.10;   % decentre vers le sommet 2
             0.10, 0.10, 0.70, 0.10;   % decentre vers le sommet 3
             0.10, 0.10, 0.10, 0.70];  % decentre vers le sommet 4

    nb_barycentres = size(poids, 1);
    nb_tetra = size(tri, 1);

    C_g = zeros(4, nb_tetra, nb_barycentres);
    for i = 1:nb_tetra
        idx_sommets = tri(i, :);
        sommets_3D = X(1:3, idx_sommets);

        for k = 1:nb_barycentres
            C_g(1:3, i, k) = sum(sommets_3D .* poids(k, :), 2);
            C_g(4, i, k) = 1;
        end
    end
end
