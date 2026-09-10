function conserves = filtrer_tetraedres_silhouette(C_g, P, labels_bin, seuil_vues)
%FILTRER_TETRAEDRES_SILHOUETTE Filtre les tetraedres par coherence de silhouette.
%
%   CONSERVES = FILTRER_TETRAEDRES_SILHOUETTE(C_g, P, labels_bin, SEUIL_VUES)
%   applique le principe de l'enveloppe visuelle ("visual hull") : un
%   tetraedre n'est conserve que si CHACUN de ses barycentres (voir
%   CALCULER_BARYCENTRES_TETRAEDRES) se projette a l'interieur du masque de
%   silhouette dans au moins SEUIL_VUES images sur le nombre total de vues
%   disponibles.
%
%
%   Entrees :
%       C_g        : 4 x nb_tetra x nb_barycentres
%       P          : cell array {1 x nb_images} - matrices de projection
%       labels_bin : cell array {1 x nb_images} - masques binaires de silhouette
%       seuil_vues : nombre minimal de vues coherentes exige pour CHAQUE barycentre
%
%   Sortie :
%       conserves : vecteur logique (nb_tetra x 1), true si le tetraedre est conserve

    nb_tetra = size(C_g, 2);
    nb_barycentres = size(C_g, 3);
    nb_images = numel(labels_bin);

    conserves = false(nb_tetra, 1);

    for t = 1:nb_tetra
        nb_valides = 0; % nombre de barycentres valides pour ce tetraedre

        for k = 1:nb_barycentres
            compteur = 0; % nombre de vues ou ce barycentre tombe dans le masque

            for i = 1:nb_images
                masque = labels_bin{i};
                [hauteur, largeur] = size(masque);

                proj = P{i} * C_g(:, t, k);
                w = proj(3);
                if abs(w) < 1e-10
                    continue; % projection degeneree, on ignore cette vue
                end

                u = round(proj(1) / w); % ligne
                v = round(proj(2) / w); % colonne

                if u >= 1 && u <= hauteur && v >= 1 && v <= largeur && masque(u, v) == 1
                    compteur = compteur + 1;
                end
            end

            if compteur >= seuil_vues
                nb_valides = nb_valides + 1;
            end
        end

        % Condition stricte : les nb_barycentres echantillons doivent
        % TOUS etre coherents avec les silhouettes
        conserves(t) = (nb_valides == nb_barycentres);
    end
end
