function [X, color] = reconstruire_points3D(pts, P, im)
%RECONSTRUIRE_POINTS3D Triangulation lineaire (SVD) d'un nuage de points 3D.
%
%   [X, COLOR] = RECONSTRUIRE_POINTS3D(pts, P, im) reconstruit les points 3D
%   correspondant aux appariements multi-vues PTS, a partir des matrices de
%   projection P{i} (3x4) de chaque camera. Pour chaque point observe dans
%   au moins 2 vues, le systeme lineaire issu des equations de projection
%   est resolu par SVD (triangulation DLT). La couleur du point est la
%   moyenne des couleurs RGB observees dans les vues qui le voient.
%
%   Entrees :
%       pts : nb_points x (2*nb_images) - coordonnees image (xi,yi) de
%             chaque point dans chaque vue (-1 si non observe)
%       P   : cell array {1 x nb_images} - matrices de projection 3x4
%       im  : nb_lignes x nb_colonnes x 3 x nb_images - images couleur
%
%   Sorties :
%       X     : 4 x nb_points_valides - coordonnees homogenes 3D
%       color : 3 x nb_points_valides - couleur RGB moyenne de chaque point

    nb_images = size(im, 4);
    X = [];
    color = [];

    for i = 1:size(pts, 1)
        % Vues dans lesquelles le point i est observe
        l = find(pts(i, 1:2:end) ~= -1);

        % On ne garde que les points observes dans au moins 2 vues, avec un
        % etalement de vues raisonnable (evite les correspondances degenerees)
        if size(l, 2) > 1 && max(l) - min(l) > 1 && max(l) - min(l) < nb_images
            A = [];
            R = 0; G = 0; B = 0;

            for j = l
                A = [A; ...
                     P{j}(1, :) - pts(i, (j - 1) * 2 + 1) * P{j}(3, :); ...
                     P{j}(2, :) - pts(i, (j - 1) * 2 + 2) * P{j}(3, :)];

                R = R + double(im(int16(pts(i, (j - 1) * 2 + 1)), int16(pts(i, (j - 1) * 2 + 2)), 1, j));
                G = G + double(im(int16(pts(i, (j - 1) * 2 + 1)), int16(pts(i, (j - 1) * 2 + 2)), 2, j));
                B = B + double(im(int16(pts(i, (j - 1) * 2 + 1)), int16(pts(i, (j - 1) * 2 + 2)), 3, j));
            end

            % Triangulation DLT : X est le vecteur singulier associe a la
            % plus petite valeur singuliere de A, normalise en coordonnees
            % homogenes
            [~, ~, V] = svd(A);
            X = [X, V(:, end) / V(end, end)]; 
            color = [color, [R; G; B] / size(l, 2)];
        end
    end
end
