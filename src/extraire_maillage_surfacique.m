function FACES = extraire_maillage_surfacique(tetra)
%EXTRAIRE_MAILLAGE_SURFACIQUE Extrait les faces de surface par parite.
%
%   FACES = EXTRAIRE_MAILLAGE_SURFACIQUE(tetra) extrait, parmi les faces
%   triangulaires des tetraedres conserves, celles qui n'appartiennent qu'a
%   un seul tetraedre : ce sont les faces de surface du volume reconstruit
%   (une face partagee par deux tetraedres est necessairement interieure
%   et est donc ecartee).
%
%   Principe :
%       1. Enumerer les 4 faces de chaque tetraedre, sommets tries pour une
%          representation canonique independante de l'orientation.
%       2. Trier l'ensemble des faces (sortrows) : les faces identiques
%          deviennent des lignes consecutives.
%       3. Parcourir la liste triee : deux lignes consecutives identiques
%          = face interieure (on l'ecarte) ; ligne isolee = face de surface
%          (on la conserve).
%
%   Entree :
%       tetra : nb_tetra x 4 - indices de sommets des tetraedres conserves
%
%   Sortie :
%       FACES : nb_faces x 3 - indices de sommets des faces de surface

    combos = [1, 2, 3; 1, 2, 4; 1, 3, 4; 2, 3, 4];
    nb_tetra = size(tetra, 1);

    FACES_all = zeros(nb_tetra * 4, 3);
    for i = 1:nb_tetra
        v = tetra(i, :);
        for f = 1:4
            FACES_all((i - 1) * 4 + f, :) = sort(v(combos(f, :)));
        end
    end

    FACES_sorted = sortrows(FACES_all);

    FACES = [];
    idx = 1;
    n = size(FACES_sorted, 1);
    while idx <= n
        if idx < n && all(FACES_sorted(idx, :) == FACES_sorted(idx + 1, :))
            idx = idx + 2; % face interieure partagee par 2 tetraedres : on l'ecarte
        else
            FACES = [FACES; FACES_sorted(idx, :)];
            idx = idx + 1;
        end
    end
end
