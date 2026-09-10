%% RECONSTRUCTION 3D PAR SILHOUETTES MULTI-VUES
% Script principal : segmentation SLIC + binarisation de 36 vues d'un
% dinosaure calibre, analyse de forme (axe median par Voronoi) sur
% quelques images temoins, puis reconstruction 3D complete (triangulation,
% tetraedrisation de Delaunay, filtrage par enveloppe visuelle et
% extraction du maillage surfacique).


clear;
close all;

%% PARAMETRES GENERAUX
nb_images = 36;

% Parametres SLIC
K_slic        = 400; % nombre de superpixels desires (finesse de la frontiere)
m_slic        = 20;  % poids de compacite spatiale
max_iter_slic = 10;  % nombre maximal d'iterations
seuil_slic    = 10;  % seuil d'arret sur le deplacement des germes

% Images sur lesquelles l'axe median (Voronoi) est calcule a titre d'illustration
images_temoins = [1, 9, 17, 25];
pas_squelette  = 4; % sous-echantillonnage du contour avant Voronoi

% Parametres de la reconstruction 3D
nb_barycentres = 5;      % nombre d'echantillons par tetraedre 
seuil_vues     = 30;     % nombre minimal de vues coherentes exige par barycentre (sur nb_images)
seuil_volume   = 1e-3;   % volume maximal tolere pour un tetraedre conserve

%% CHARGEMENT DES IMAGES
im = [];
for i = 1:nb_images
    if i <= 10
        nom = sprintf('images/viff.00%d.ppm', i - 1);
    else
        nom = sprintf('images/viff.0%d.ppm', i - 1);
    end
    im(:, :, :, i) = imread(nom);
end


%% ============================================================
%% PARTIE 1 - SEGMENTATION ET MASQUES (SLIC + binarisation)
%% ============================================================
% Pour chaque vue : sur-segmentation en superpixels (SLIC, espace LAB),
% puis binarisation dinosaure / fond. Les masques sont conserves pour
% servir de test de silhouette dans la reconstruction 3D (partie 3).

labels_bin = cell(1, nb_images);

for i = 1:nb_images
    fprintf('Segmentation de l''image %d/%d...\n', i, nb_images);
    img = im(:, :, :, i);

    [germes_color, labels, germes_x, germes_y] = calcul_superpixels_slic( ...
        img, K_slic, max_iter_slic, m_slic, seuil_slic);

    masque_courant = binariser_dino_lab(germes_color, labels);
    labels_bin{i} = masque_courant;

    %% ------------------------------------------------------------
    %% PARTIE 2 - ANALYSE DE FORME (axe median par Voronoi)
    %% ------------------------------------------------------------
    % Calcule a titre d'illustration sur quelques images temoins
    % uniquement (cout du diagramme de Voronoi) ; n'intervient pas dans
    % la reconstruction 3D de la partie 3.
    if ismember(i, images_temoins)
        [contour, Squelette_X, Squelette_Y, Adjacence, Rayons] = ...
            calcul_squelette_voronoi(masque_courant, pas_squelette);

        figure(2); clf;
        set(gcf, 'Name', sprintf('Resultats image %d', i), ...
            'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);

        subplot(2, 3, 1);
        imagesc(uint8(img)); hold on;
        plot(germes_x, germes_y, 'y+', 'MarkerSize', 5, 'LineWidth', 1);
        title('1. Image & centres SLIC'); axis off; hold off;

        subplot(2, 3, 2);
        imagesc(labels); colormap(gca, lines(numel(germes_x)));
        title('2. Regions superpixels'); axis off;

        subplot(2, 3, 3);
        imshow(labels_bin{i});
        title('3. Masque binaire');

        subplot(2, 3, 4);
        imshow(labels_bin{i}); hold on;
        plot(contour(:, 2), contour(:, 1), 'g.', 'MarkerSize', 4);
        title('4. Extraction du contour'); hold off;

        subplot(2, 3, 5);
        imshow(labels_bin{i}); hold on;
        gplot(Adjacence, [Squelette_X, Squelette_Y], 'm-');
        title('5. Axe median (Voronoi)'); hold off;

        subplot(2, 3, 6);
        imshow(labels_bin{i}); hold on;
        gplot(Adjacence, [Squelette_X, Squelette_Y], 'm-');
        theta = linspace(0, 2 * pi, 30);
        ux = cos(theta); uy = sin(theta);
        for c_i = 1:length(Squelette_X)
            fill(Squelette_X(c_i) + Rayons(c_i) * ux, Squelette_Y(c_i) + Rayons(c_i) * uy, ...
                'y', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
        end
        plot(Squelette_X, Squelette_Y, 'r.', 'MarkerSize', 5);
        title('6. Cercles inscrits'); hold off;
        drawnow;
    end
end


%% ============================================================
%% PARTIE 3 - RECONSTRUCTION 3D (points, Delaunay, filtrage, maillage)
%% ============================================================

%% 3.1 Reconstruction du nuage de points 3D (triangulation SVD)
% pts : correspondances multi-vues (viff.xy)
% P   : matrices de projection 3x4 de chaque camera (dino_Ps)
pts = load('viff.xy');
load dino_Ps; % charge la variable P (cell array)

[X, color] = reconstruire_points3D(pts, P, im);
fprintf('Reconstruction 3D terminee : %d points trouves.\n', size(X, 2));

figure;
hold on;
for i = 1:size(X, 2)
    plot3(X(1, i), X(2, i), X(3, i), '.', 'Color', color(:, i) / 255);
end
axis equal;
title('Nuage de points 3D reconstruit');

%% 3.2 Tetraedrisation de Delaunay
T = DelaunayTri(X(1, :)', X(2, :)', X(3, :)');
tri = T.Triangulation;
fprintf('Tetraedrisation terminee : %d tetraedres trouves.\n', size(tri, 1));

figure;
tetramesh(T);
title('Tetraedrisation de Delaunay (brute)');

%% 3.3 Filtrage des tetraedres par coherence avec les silhouettes
% Enveloppe visuelle : un tetraedre n'est conserve que si TOUS ses
% barycentres se projettent dans le masque de silhouette d'au moins
% seuil_vues images sur nb_images
C_g = calculer_barycentres_tetraedres(X, tri);
conserves = filtrer_tetraedres_silhouette(C_g, P, labels_bin, seuil_vues);
Tbis_temp = tri(conserves, :);

%% 3.4 Filtrage des tetraedres par volume
% Ecarte les tetraedres de grande taille ayant passe le test precedent
% par coincidence
Tbis = filtrer_tetraedres_volume(Tbis_temp, X, seuil_volume);
fprintf('Filtrage termine : %d tetraedres conserves (sur %d).\n', size(Tbis, 1), size(tri, 1));

figure;
trisurf(Tbis, X(1, :), X(2, :), X(3, :));
title(sprintf('Tetraedres conserves apres filtrage (%d)', size(Tbis, 1)));

% Point de sauvegarde intermediaire (etape couteuse en calcul)
save donnees Tbis X color labels_bin P;

%% 3.5 Extraction du maillage surfacique (parite des faces)
FACES = extraire_maillage_surfacique(Tbis);
fprintf('Calcul du maillage final termine : %d faces.\n', size(FACES, 1));

figure;
hold on;
for i = 1:size(FACES, 1)
    plot3([X(1, FACES(i, 1)) X(1, FACES(i, 2))], ...
          [X(2, FACES(i, 1)) X(2, FACES(i, 2))], ...
          [X(3, FACES(i, 1)) X(3, FACES(i, 2))], 'r');
    plot3([X(1, FACES(i, 1)) X(1, FACES(i, 3))], ...
          [X(2, FACES(i, 1)) X(2, FACES(i, 3))], ...
          [X(3, FACES(i, 1)) X(3, FACES(i, 3))], 'r');
    plot3([X(1, FACES(i, 3)) X(1, FACES(i, 2))], ...
          [X(2, FACES(i, 3)) X(2, FACES(i, 2))], ...
          [X(3, FACES(i, 3)) X(3, FACES(i, 2))], 'r');
end
axis equal;
title(sprintf('Maillage surfacique final - %d faces', size(FACES, 1)));
