-- -----------------------------------------------------------------------------
                -- Wish 1
                -- -----------------------------------------------------------------------------

                CREATE TABLE `Wish 1` AS

                  SELECT Lieu.designation, top, Dieu.nom, compte
                  FROM (

                    SELECT @row_number:=CASE
                      WHEN @place_no = ID_Lieu
                        THEN @row_number + 1
                      ELSE 1
                      END AS top,
                      @place_no:= ID_Lieu ID_Lieu, compte, ID_Dieu
                    FROM (

                      SELECT ID_Lieu, ID_Dieu, COUNT(*) AS `compte` FROM `vente`
                      WHERE ID_Lieu IS NOT NULL
                      AND ID_Dieu IS NOT NULL
                      GROUP BY ID_Dieu, ID_Lieu
                      ORDER BY ID_Lieu ASC, compte DESC

                    ) AS b, (SELECT @place_no:=0, @row_number:=0) AS a
                  ) AS c

                  INNER JOIN YFANSI.Dieu
                  ON c.ID_Dieu = Dieu.ID
                  INNER JOIN YFANSI.Lieu
                  ON c.ID_Lieu = Lieu.ID

                  WHERE top <= 5
                  ORDER BY Lieu.designation, top
                ;

                -- -----------------------------------------------------------------------------
                -- Wish 2
                -- -----------------------------------------------------------------------------

                CREATE VIEW `Wish 2` AS

                  SELECT Objet.designation AS `Objet`, ROUND(AVG(`Prix/Unité`)) AS `Prix Moyen`
                  FROM (
                    SELECT  ID_Vente, ID_Objet ,
                      SUM((quantite_monnaie * Monnaie.quantite )/quantite_objet) AS `Prix/Unité`

                    FROM valoriser

                    INNER JOIN vente
                    ON valoriser.ID_Vente = vente.ID

                    INNER JOIN monnaie
                    ON valoriser.ID_Monnaie = monnaie.ID

                    GROUP BY ID_Vente
                  ) AS t1

                  INNER JOIN Objet
                  ON t1.ID_Objet = objet.ID

                  GROUP BY ID_Objet
                ;

                -- -----------------------------------------------------------------------------
                -- Wish 3
                -- -----------------------------------------------------------------------------

                CREATE VIEW `Wish 3` AS

                  SELECT Dieu.nom AS `Nom de la divinité`, nombre AS `Nombre d'objets vendus`
                  FROM (
                    SELECT ID_Dieu, COUNT(*) AS Nombre
                    FROM vente

                    WHERE ID_Dieu IS NOT NULL

                    GROUP BY ID_Dieu
                    HAVING Nombre = (
                      SELECT MAX(nombre) FROM (
                        SELECT ID_Dieu, COUNT(*) AS Nombre
                        FROM vente

                        WHERE ID_Dieu IS NOT NULL

                        GROUP BY ID_Dieu
                      ) AS t2
                    )
                  ) AS t1

                  INNER JOIN Dieu
                  ON t1.ID_Dieu = Dieu.ID
                ;

                -- -----------------------------------------------------------------------------
                -- Wish 4
                -- -----------------------------------------------------------------------------

                CREATE VIEW `Wish 4` AS

                  SELECT LaProvince.*, lesAutres.Autres
                  FROM (
                    SELECT annee, COUNT(*) AS `AEgypte`
                    FROM vente

                    WHERE ID_Lieu = 4

                    GROUP BY vente.annee
                  ) AS LaProvince

                  INNER JOIN (

                    SELECT annee, ROUND(AVG(`Autres`)) AS `Autres`
                    FROM (

                      SELECT annee, ID_Lieu, COUNT(*) AS `Autres` FROM vente

                      WHERE ID_Lieu != 4

                      GROUP BY ID_Lieu, annee

                    ) AS t1

                    GROUP BY annee

                  ) AS LesAutres

                  ON LaProvince.annee = LesAutres.annee
                ;
                -- -----------------------------------------------------------------------------
                -- Wish 5
                -- -----------------------------------------------------------------------------

                CREATE VIEW `Wish 5` AS

                  SELECT Dieu.nom AS `Nom du Dieu`, Mois.designation AS `Mois`, compte AS `Nombre de vente`
                  FROM (

                    SELECT COUNT(*) AS compte, ID_Mois, ID_Dieu FROM vente
                    WHERE (ID_Mois,ID_Dieu) IN (SELECT ID, ID_Dieu FROM mois)
                    GROUP BY ID_Mois

                    UNION ALL

                    SELECT ROUND(AVG(compte)) AS moyenne,"restant de l'année",  ID_Dieu
                    FROM(

                      SELECT COUNT(*) AS compte, ID_Dieu, ID_Mois FROM vente
                      WHERE ID_Dieu IN (SELECT ID_Dieu FROM mois)
                      AND (ID_Mois,ID_Dieu) NOT IN (SELECT ID, ID_Dieu FROM mois)
                      GROUP BY ID_Dieu, ID_Mois

                    ) AS table1
                    GROUP BY ID_Dieu
                  ) AS table2

                  LEFT JOIN mois
                  ON table2.ID_Mois = mois.ID
                  INNER JOIN dieu
                  ON table2.ID_Dieu = Dieu.ID

                  ORDER BY table2.ID_Dieu
                ;
                -- -----------------------------------------------------------------------------
                -- Wish 6
                -- -----------------------------------------------------------------------------

                CREATE VIEW `Wish 6` AS

                  SELECT Lieu.designation AS `Lieu`, table3.a AS `Situation`, table3.compte AS `Nombre de ventes`
                  FROM (

                    SELECT ROUND(AVG(compte)) AS compte, ID_Lieu, "guerre" AS a
                    FROM (

                      SELECT COUNT(*) AS compte, annee, ID_Lieu
                      FROM vente
                      WHERE (annee, ID_Lieu) IN (SELECT annee, ID_Lieu FROM guerre)
                      GROUP BY ID_Lieu, annee
                    ) AS table1
                    GROUP BY ID_Lieu

                    UNION ALL

                    SELECT ROUND(AVG(compte)) AS compte, ID_Lieu,"pas guerre" AS a
                    FROM (

                      SELECT COUNT(*) AS compte, annee, ID_Lieu
                      FROM vente
                      WHERE (annee, ID_Lieu) NOT IN (SELECT annee, ID_Lieu FROM guerre)
                      GROUP BY ID_Lieu, annee
                    ) AS table2
                    GROUP BY ID_Lieu
                  ) AS table3

                  INNER JOIN lieu
                  ON table3.ID_Lieu = lieu.ID

                  ORDER BY ID_Lieu
                ;

                -- -----------------------------------------------------------------------------
                -- Wish 7
                -- -----------------------------------------------------------------------------

                CREATE TABLE `NewVente` (

                  `jour`              DECIMAL(2,0) NOT NULL,
                  `mois`              VARCHAR(100) NOT NULL,
                  `annee`             DECIMAL(3,0),
                  `objet`             VARCHAR(256) NOT NULL,
                  `quantité d'objet`  INT UNSIGNED NOT NULL,
                  `Don à`             VARCHAR(256),
                  `Lieu`              VARCHAR(256),
                  `Divinité associée` VARCHAR(256)

                ) ENGINE = InnoDB;

                DELIMITER |

                DROP TRIGGER IF EXISTS insert_NV|

                CREATE TRIGGER insert_NV AFTER INSERT
                ON YFANSI.NewVente FOR EACH ROW

                BEGIN

                DECLARE LeJour    DECIMAL(2,0);
                DECLARE LeMois    VARCHAR(100);
                DECLARE LaAnnee   DECIMAL(3,0);
                DECLARE LeObjet   VARCHAR(256);
                DECLARE LaQte     INT UNSIGNED;
                DECLARE LeDon     VARCHAR(256);
                DECLARE LeLieu    VARCHAR(256);
                DECLARE LeDieu    VARCHAR(256);

                SET LeJour = NEW.jour;
                SET LeMois = NEW.mois;
                SET LaAnnee = NEW.annee;
                SET LeObjet = NEW.objet;
                SET LaQte = NEW.`quantité d'objet`;
                SET LeDon = NEW.`Don à`;
                SET LeLieu = NEW.Lieu;
                SET LeDieu = NEW.`Divinité associée`;

                CALL SP_insert_NV(LeJour, LeMois, LaAnnee, LeObjet, LaQte, LeDon, LeLieu, LeDieu);

                END|

                DELIMITER |

                DROP PROCEDURE IF EXISTS SP_insert_NV|

                CREATE PROCEDURE SP_insert_NV (

                  IN Pjour      DECIMAL(2,0),
                  IN Pmois      VARCHAR(256),
                  IN Pannee     DECIMAL(3,0),
                  IN Pobjet     VARCHAR(256),
                  IN Pqte       INT UNSIGNED,
                  IN Pdon       VARCHAR(256),
                  IN Plieu      VARCHAR(256),
                  IN Pdieu      VARCHAR(256)

                )

                BEGIN

                DECLARE Psiecle   DECIMAL(1,0);
                DECLARE ID_Pmois  INT UNSIGNED;
                DECLARE ID_Pobjet INT UNSIGNED;
                DECLARE ID_Pdon   INT UNSIGNED DEFAULT NULL;
                DECLARE ID_Plieu  INT UNSIGNED DEFAULT NULL;
                DECLARE ID_Pdieu  INT DEFAULT NULL;

                SELECT SUBSTRING(Pannee FROM 1 FOR 1) + 1 INTO Psiecle;


                SELECT ID INTO ID_Pobjet
                FROM objet
                WHERE designation = Pobjet;

                SELECT ID INTO ID_Pmois
                FROM mois
                WHERE designation = Pmois;

                IF (Pdon IS NOT NULL) THEN

                  SELECT ID INTO ID_Pdon
                  FROM demidieu
                  WHERE nom = Pdon;

                END IF;

                IF (Plieu IS NOT NULL) THEN

                  SELECT ID INTO ID_Plieu
                  FROM lieu
                  WHERE designation = Plieu;

                END IF;

                IF (Pdieu IS NOT NULL) THEN

                  SELECT ID INTO ID_Pdieu
                  FROM dieu
                  WHERE nom = Pdieu;

                END IF;

                INSERT INTO YFANSI.vente (`jour`, `annee`, `siecle`, `quantite_objet`,
                   `ID_Objet`, `ID_Mois`, `ID_DemiDieu`, `ID_Lieu`, `ID_Dieu`)
                VALUES (Pjour, Pannee, Psiecle, Pqte, ID_Pobjet, ID_Pmois, ID_Pdon, ID_Plieu, ID_Pdieu);

                END|


                -- test with Thargélion, Cuirasse de cuir, Achaïe, Apollon

                -- -----------------------------------------------------------------------------
                -- Wish 8
                -- -----------------------------------------------------------------------------

                CREATE VIEW `Wish 8` AS

                  SELECT lieu.designation AS lieu,guerre.annee, objet.designation AS Objet,
                    SUM(CASE WHEN vente2.annee BETWEEN guerre.annee AND (guerre.annee + 10) THEN 1 ELSE 0 END) AS apres,
                    SUM(CASE WHEN vente2.annee BETWEEN (guerre.annee -50) AND guerre.annee THEN 1 ELSE 0 END)/5 AS avant
                  FROM guerre

                  INNER JOIN vente AS vente1
                  ON guerre.ID_DemiDieu = vente1.ID_DemiDieu
                  AND vente1.annee < guerre.annee

                  INNER JOIN vente AS vente2
                  ON vente1.ID_Objet = vente2.ID_Objet
                  AND guerre.ID_Lieu = vente2.ID_Lieu

                  INNER JOIN lieu
                  ON guerre.ID_Lieu = lieu.ID

                  INNER JOIN objet
                  ON vente1.ID_Objet = objet.ID

                  GROUP BY guerre.annee, guerre.ID_Lieu, vente1.ID_Objet

                  ORDER BY lieu.designation, guerre.annee, objet.designation
                ;

                -- -----------------------------------------------------------------------------
                -- Wish 9
                -- -----------------------------------------------------------------------------

                CREATE VIEW `Wish 9`AS

                  SELECT Artisan.nom AS `Artisan`,vente.siecle, count(*) AS `Nombre de ventes` FROM conclure
                  INNER JOIN vente
                  ON vente.ID = conclure.ID_Vente
                  INNER JOIN artisan
                  ON conclure.ID_Artisan = artisan.ID
                  GROUP BY conclure.ID_Artisan, siecle
                  ORDER BY Artisan.nom, vente.siecle ASC
                ;

                -- -----------------------------------------------------------------------------
                -- Wish 10
                -- -----------------------------------------------------------------------------

                SELECT first.nom AS `Artisan 1`, sec.nom AS `Artisan 2`, dieu.nom AS `Divinité`, prix AS `Prix Moyen`
                FROM (

                  SELECT ID_Dieu, art1, art2, MAX(compte), Prix
                  FROM (

                    SELECT ID_Dieu, art1, art2, COUNT(*) AS compte, ROUND(AVG(Prix)) AS Prix
                    FROM (

                      SELECT binomes.ID_Vente, binomes.art1, binomes.art2,
                        SUM(valoriser.quantite_monnaie * Mney.quantite) AS Prix
                      FROM (
                        SELECT conclure.ID_Vente, conclure.ID_Artisan AS art1, Liste2.ID_Artisan AS art2
                        FROM conclure

                        INNER JOIN (
                          SELECT ID_Artisan, ID_Vente FROM (
                            SELECT @row_number:=CASE
                              WHEN @place_no = ID_Vente THEN @row_number + 1 ELSE 1 END AS top,
                              @place_no:= ID_Vente ID_Lieu, a.*

                            FROM (SELECT * FROM conclure ORDER BY ID_Vente) AS a,
                              (SELECT @place_no:=0, @row_number:=0) AS b
                          ) AS c

                          WHERE top = 2
                        ) AS Liste2

                        ON conclure.ID_Vente = Liste2.ID_vente
                        AND conclure.ID_Artisan <> Liste2.ID_Artisan
                      ) AS binomes

                      INNER JOIN valoriser
                      ON binomes.ID_Vente = valoriser.ID_Vente

                      INNER JOIN (SELECT ID, quantite FROM Monnaie) AS Mney
                      ON valoriser.ID_Monnaie = Mney.ID

                      GROUP BY binomes.ID_Vente, binomes.art1, binomes.art2
                    ) AS BiPrix
                    INNER JOIN (SELECT ID_Dieu, ID FROM vente WHERE ID_Dieu IS NOT NULL) AS vt
                    ON BiPrix.ID_Vente = vt.ID

                    GROUP BY ID_Dieu, art1, art2
                  ) AS Best

                  GROUP BY art1, art2

                ) AS IDS

                INNER JOIN Dieu
                ON IDS.ID_Dieu = Dieu.ID

                INNER JOIN artisan AS first
                ON IDS.art1 = first.ID

                INNER JOIN artisan AS sec
                ON IDS.art2 = sec.ID

                UNION ALL

                SELECT * FROM `Wish 10.z`

                ORDER BY `Divinité`, `Prix Moyen`

                INTO OUTFILE "E:\CESI\Projet\BDD\Scripts\Wish10z.csv"
                FIELDS TERMINATED BY ','
                ENCLOSED BY '"'
                LINES TERMINATED BY '\n'
                ;
                -- -----------------------------------------------------------------------------

                CREATE VIEW `Wish 10.z` AS

                  SELECT art.nom AS `Artisan 1`, NULL AS `Artisan 2`, dieu.nom AS `Divinité`, prix AS `Prix Moyen`
                  FROM (

                    SELECT ID_Dieu, ID_Artisan, MAX(compte), Prix
                    FROM (

                      SELECT ID_Dieu, ID_Artisan, COUNT(*) AS compte, ROUND(AVG(Prix)) AS Prix
                      FROM (

                        SELECT solo.ID_Vente, solo.ID_Artisan,
                          SUM(valoriser.quantite_monnaie * Mney.quantite) AS Prix
                        FROM (

                          SELECT ID_Vente, ID_Artisan, COUNT(*) FROM conclure
                          GROUP BY ID_vente
                          HAVING COUNT(*) < 2
                        ) AS solo

                        INNER JOIN valoriser
                        ON solo.ID_Vente = valoriser.ID_Vente

                        INNER JOIN (SELECT ID, quantite FROM Monnaie) AS Mney
                        ON valoriser.ID_Monnaie = Mney.ID

                        GROUP BY solo.ID_Vente, solo.ID_Artisan
                      ) AS SoPrix

                      INNER JOIN (SELECT ID_Dieu, ID FROM vente WHERE ID_Dieu IS NOT NULL) AS vt
                      ON SoPrix.ID_Vente = vt.ID

                      GROUP BY ID_Dieu, ID_Artisan
                    ) AS Beste

                    GROUP BY ID_Artisan
                  ) AS IDSS

                  INNER JOIN Dieu
                  ON IDSS.ID_Dieu = Dieu.ID

                  INNER JOIN artisan AS art
                  ON IDSS.ID_Artisan = art.ID
                ;

                -- -----------------------------------------------------------------------------
                -- Wish 11
                -- -----------------------------------------------------------------------------

                CREATE VIEW `Wish 11.1` AS

                  SELECT ListeDons.ID_DemiDieu AS ID_DD, ListeDons.annee, ListeDons.ID_Objet AS ID_Obj,
                    SUM(CASE WHEN vente2.annee BETWEEN (ListeDons.annee -35) AND ListeDons.annee THEN 1 ELSE 0 END)/5 AS avant,
                    SUM(CASE WHEN vente2.annee BETWEEN ListeDons.annee AND (ListeDons.annee +35) THEN 1 ELSE 0 END)/5 AS apres
                  FROM (
                    SELECT annee, ID_DemiDieu, ID_Objet
                    FROM vente
                    WHERE vente.ID_DemiDieu IS NOT NULL
                  ) AS ListeDons
                  INNER JOIN vente AS vente2
                  ON ListeDons.ID_Objet = vente2.ID_Objet

                  GROUP BY ListeDons.annee, ListeDons.ID_Objet
                ;

                CREATE VIEW `Wish 11.f` AS

                  SELECT DemiDieu.nom AS Sponsor, wish.annee, objet.designation AS Objet, avant, apres
                  FROM `Wish 11.1` AS wish

                  INNER JOIN objet
                  ON wish.ID_Obj = objet.ID

                  INNER JOIN demidieu
                  ON wish.ID_DD = DemiDieu.ID

                  ORDER BY DemiDieu.nom, wish.annee, objet.designation
                ;

                CREATE VIEW `Wish 11.z` AS

                  SELECT wisheu.*, wisheuu.`Prix Moyen` AS `Prix moyen`
                  FROM `Wish 11.f` AS wisheu
                  INNER JOIN `Wish 2` AS wisheuu
                  ON wisheu.Objet = wisheuu.Objet

                ;

                -- -----------------------------------------------------------------------------
                -- Wish 12
                -- -----------------------------------------------------------------------------

                CREATE VIEW `Wish 12` AS

                  SELECT lieu.designation AS Lieu, AVG((GoldPart/Total*100)) AS `Percentage of gold`
                  FROM (
                    SELECT * FROM (
                      SELECT valoriser.ID_Vente, SUM(quantite_monnaie*quantite) AS Total
                      FROM valoriser

                      INNER JOIN monnaie
                      ON valoriser.ID_Monnaie = monnaie.ID

                      GROUP BY ID_Vente
                    ) AS toto

                    INNER JOIN (
                      SELECT valoriser.ID_Vente AS a, SUM(quantite_monnaie*quantite) AS GoldPart
                      FROM valoriser

                      INNER JOIN monnaie
                      ON valoriser.ID_Monnaie = monnaie.ID

                      WHERE ID_Monnaie = 1
                      GROUP BY ID_Vente
                    ) AS gold
                    ON toto.ID_Vente = gold.a
                  ) AS percent

                  INNER JOIN vente
                  ON percent.ID_Vente = vente.ID

                  INNER JOIN lieu
                  ON vente.ID_Lieu = lieu.ID

                  GROUP BY ID_Lieu

                  ORDER BY `Percentage of gold` DESC
                ;
              
            