function tetra_filtres = filtrer_tetraedres_volume(tetra, X, seuil_volume)
%FILTRER_TETRAEDRES_VOLUME Retire les tetraedres dont le volume est trop grand.
%
%   TETRA_FILTRES = FILTRER_TETRAEDRES_VOLUME(tetra, X, SEUIL_VOLUME) supprime,
%   parmi les tetraedres TETRA (indices de sommets), ceux dont le volume
%   depasse SEUIL_VOLUME. Ce second filtre elimine les tetraedres qui
%   auraient passe le test de silhouette par coincidence — generalement de
%   grande taille et visuellement genants dans le maillage final.
%
%   Entrees :
%       tetra        : nb_tetra x 4 - indices de sommets
%       X            : 3 x nb_points (ou 4 x nb_points homogene) - nuage de points 3D
%       seuil_volume : volume maximal tolere
%
%   Sortie :
%       tetra_filtres : sous-ensemble de TETRA dont le volume est <= seuil_volume

    nb_tetra = size(tetra, 1);
    a_retirer = false(nb_tetra, 1);

    for i = 1:nb_tetra
        s = tetra(i, :);
        A = X(1:3, s(1));
        B = X(1:3, s(2));
        C = X(1:3, s(3));
        D = X(1:3, s(4));

        volume = abs(det([B - A, C - A, D - A])) / 6;

        if volume > seuil_volume
            a_retirer(i) = true;
        end
    end

    tetra_filtres = tetra(~a_retirer, :);
end
