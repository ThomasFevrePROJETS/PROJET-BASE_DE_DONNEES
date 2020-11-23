 -- -----------------------------------------------------------------------------
                -- Table : Type_Option
                -- -----------------------------------------------------------------------------

                CREATE TABLE ventes.`Type_Option` (

                  `ID`           INT AUTO_INCREMENT NOT NULL,
                  `designation`  VARCHAR(100) NOT NULL,

                  CONSTRAINT PK_Type_Option
                    PRIMARY KEY(`id`)
                ) ENGINE = InnoDB ;

                INSERT INTO `Type_Option`(`designation`)
                VALUES ("pouvoir"), ("décoration");

                -- -----------------------------------------------------------------------------
                -- Table : Dieu
                -- -----------------------------------------------------------------------------

                CREATE TABLE ventes.`Dieu` (

                  `ID`  INT AUTO_INCREMENT NOT NULL,
                  `nom` VARCHAR(256) NOT NULL,

                  CONSTRAINT PK_Dieu
                    PRIMARY KEY(`ID`)

                ) ENGINE = InnoDB;

                SELECT DISTINCT `Fils ou Fille de` -- > DIEUX
                FROM ventes_avant.demidieu;

                /*
                SELECT SUBSTRING_INDEX(Deco, " d'", -1) AS Deco        VERIF DES INFOS DU SELECT
                FROM (
                  SELECT DISTINCT Deco_1 AS Deco FROM ventes_avant.tmp_deco      DEPUIS LA TABLE DES VENTES
                  UNION
                  SELECT DISTINCT Deco_2 FROM ventes_avant.tmp_deco
                ) AS tmp_deco1
                WHERE Deco LIKE "% d'%"

                UNION  -- listes des décos différentes

                SELECT SUBSTRING_INDEX(Deco, " de ", -1) AS Deco
                FROM (
                  SELECT DISTINCT Deco_1 AS Deco FROM ventes_avant.tmp_deco
                  UNION
                  SELECT DISTINCT Deco_2 FROM ventes_avant.tmp_deco
                ) AS tmp_deco2
                WHERE Deco NOT LIKE "% d'%"
                ;
                */

                INSERT INTO `Dieu` (`nom`)
                SELECT DISTINCT `Fils ou Fille de`
                FROM ventes_avant.demidieu;

                -- -----------------------------------------------------------------------------
                -- Table : DemiDieu
                -- -----------------------------------------------------------------------------

                CREATE TABLE `ventes`.`DemiDieu` (

                  `ID`      INT UNSIGNED AUTO_INCREMENT NOT NULL,
                  `nom`     VARCHAR(256) NOT NULL,
                  `ID_Dieu` INT NOT NULL,

                  CONSTRAINT PK_DemiDieu
                    PRIMARY KEY(`ID`)

                ) ENGINE = InnoDB;

                INSERT INTO ventes.demidieu (`nom`, `ID_Dieu`)
                  SELECT DISTINCT SUBSTRING(child.`Demi Dieu` FROM 2), parent.ID
                  FROM ventes_avant.demidieu AS child -- DEMIDIEUX
                  INNER JOIN ventes.Dieu AS parent
                  ON child.`Fils ou fille de` = parent.nom
                ;

                -- -----------------------------------------------------------------------------
                -- Table : Guerre
                -- -----------------------------------------------------------------------------

                CREATE TABLE `ventes`.`tmp_guerre` (

                    `lieu` VARCHAR(256) NOT NULL ,
                    `annee` VARCHAR(256) NOT NULL ,
                    `demidieu` VARCHAR(256)
                ) ENGINE = InnoDB;

                -- -----------------------------------------------------------------------------
                DELIMITER |
                DROP FUNCTION IF EXISTS ventes_avant.reduce_str|

                CREATE FUNCTION ventes_avant.reduce_str(
                  str   VARCHAR(1312),
                  delim VARCHAR(50),
                  pos   INT
                ) RETURNS VARCHAR(255)
                RETURN
                  REPLACE(SUBSTRING(SUBSTRING_INDEX(str, delim, pos),
                  LENGTH(SUBSTRING_INDEX(str, delim, pos-1)) + 1),
                  delim, '')
                |

                -- -----------------------------------------------------------------------------

                DELIMITER |
                DROP PROCEDURE IF EXISTS ventes_avant.NewWar|

                CREATE PROCEDURE ventes_avant.NewWar()

                  BEGIN

                  DECLARE LeDemiDieu  VARCHAR(256); -- value
                  DECLARE LaAnnee     VARCHAR(256);  -- part
                  DECLARE LaGuerre    VARCHAR(256); -- val
                  DECLARE compteur    INT UNSIGNED DEFAULT 1;
                  DECLARE LaProvince  VARCHAR(256);
                  DECLARE LesGuerres  VARCHAR(1312);
                  DECLARE done        INT DEFAULT FALSE;

                  DECLARE CurGuerre CURSOR FOR SELECT `Province/Citée`,
                    `Année de guerre - (Demi Dieu éventuel)`
                    FROM ventes_avant.guerre;
                  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
                  OPEN CurGuerre;

                  TRUNCATE TABLE ventes.tmp_guerre;

                  LaBoucle: LOOP
                    FETCH CurGuerre INTO LaProvince, LesGuerres;
                    IF done THEN
                      LEAVE LaBoucle;
                    END IF;

                    SET compteur = 1;
                    WHILE (CHAR_LENGTH(reduce_str(LesGuerres,';',compteur)) > 0) DO

                      SET LaGuerre = reduce_str(LesGuerres, ';', compteur);
                      SET LaAnnee = reduce_str(LaGuerre, ' ', 1);
                      SET LeDemiDieu = reduce_str(LaGuerre, ' ', 2);

                      INSERT INTO ventes.tmp_guerre (lieu, annee, demidieu)
                      VALUES (LaProvince, LaAnnee, LeDemiDieu);

                      SET compteur = compteur +1;
                    END WHILE;

                  END LOOP Laboucle;
                  CLOSE CurGuerre;
                END |

                CALL NewWar();

                UPDATE ventes.tmp_guerre
                SET demidieu = REPLACE(REPLACE(demidieu, "(", ""), ")", "")
                WHERE demidieu LIKE "(%)";

                UPDATE ventes.tmp_guerre
                SET demidieu = NULL
                WHERE demidieu LIKE "";

                UPDATE ventes.tmp_guerre
                SET lieu = SUBSTRING_INDEX(lieu, " - ", -1)
                WHERE lieu LIKE "% - %";

                CREATE TABLE ventes.`Guerre` (

                  `ID`          INT UNSIGNED AUTO_INCREMENT NOT NULL,
                  `annee`       INT NOT NULL,
                  `ID_DemiDieu` INT UNSIGNED ,
                  `ID_Lieu`     INT UNSIGNED NOT NULL,

                  CONSTRAINT PK_Guerre
                    PRIMARY KEY(`ID`)

                ) ENGINE = InnoDB;


                INSERT INTO ventes.guerre (`annee`, `ID_DemiDieu`, `ID_Lieu`)
                  SELECT war.annee, fighter.ID, field.ID
                  FROM ventes.tmp_guerre AS war
                  LEFT JOIN ventes.demidieu AS fighter
                  ON war.demidieu = fighter.nom
                  INNER JOIN ventes.lieu AS field
                  ON war.lieu = field.designation
                ;

                DROP TABLE ventes.tmp_guerre;

                -- -----------------------------------------------------------------------------
                -- Table : Moulaga ( Union des 5 siècles de ventes )
                -- -----------------------------------------------------------------------------

                CREATE TABLE `Moulaga` AS
                SELECT * FROM ventes_avant.siecle1
                UNION ALL
                SELECT * FROM ventes_avant.siecle2
                UNION ALL
                SELECT * FROM ventes_avant.siecle3
                UNION ALL
                SELECT * FROM ventes_avant.siecle4
                UNION ALL
                SELECT * FROM ventes_avant.siecle5;

                ALTER TABLE `Moulaga`
                  ADD COLUMN `ID` INT AUTO_INCREMENT NOT NULL FIRST,
                  ADD CONSTRAINT PK_Moulaga
                    PRIMARY KEY(`ID`),
                    ADD INDEX `ID_Deco`(`ID`, `Decoration`)
                ;

                -- -----------------------------------------------------------------------------
                -- Table : Option
                -- -----------------------------------------------------------------------------

                CREATE TABLE  `ventes`.`Option` (

                  `ID`             INT UNSIGNED AUTO_INCREMENT NOT NULL,
                  `designation`    VARCHAR(256) NOT NULL,
                  `ID_Type_Option` INT NOT NULL,

                  CONSTRAINT PK_Option
                    PRIMARY KEY(`ID`)

                ) ENGINE = InnoDB;

                -- -----------------------------------------------------------------------------

                CREATE TABLE `tmp_deco` AS
                  SELECT DISTINCT SUBSTRING_INDEX(`Decoration`, ' &', 1) AS Deco_1,
                    SUBSTRING_INDEX(`Decoration`, '& ', -1) AS Deco_2
                    FROM ventes_avant.Moulaga
                    WHERE Decoration LIKE '%&%'

                  UNION

                  SELECT DISTINCT SUBSTRING_INDEX(`Decoration`, ' &', 1) AS Deco_1,
                    '' AS Deco_2
                  FROM ventes_avant.Moulaga
                  WHERE Decoration NOT LIKE '%&%'
                ;

                -- -----------------------------------------------------------------------------

                INSERT INTO ventes.option(`designation`, `ID_Type_Option`)
                  SELECT DISTINCT SF_split(Deco_1, 1), 2 FROM ventes_avant.tmp_deco
                  WHERE Deco_1 NOT LIKE ""

                  UNION

                  SELECT DISTINCT SF_split(Deco_2, 1), 2 FROM ventes_avant.tmp_deco
                  WHERE Deco_2 NOT LIKE ""
                ;

                -- -----------------------------------------------------------------------------

                INSERT INTO ventes.option(`designation`, `ID_Type_Option`)
                  SELECT DISTINCT `Pouvoir`, 1 FROM ventes_avant.moulaga2
                  WHERE `Pouvoir` NOT LIKE ""
                ;

                -- -----------------------------------------------------------------------------
                -- Table : Artisan
                -- -----------------------------------------------------------------------------

                CREATE TABLE `tmp_artisans` AS
                SELECT DISTINCT Artisan FROM ventes_avant.moulaga;

                CREATE TABLE `ventes`.`Artisan` (

                  `ID`   INT UNSIGNED AUTO_INCREMENT NOT NULL,
                  `nom`  VARCHAR(256) NOT NULL,

                  CONSTRAINT PK_Artisan
                    PRIMARY KEY(`ID`)

                ) ENGINE = InnoDB;


                INSERT INTO ventes.Artisan(`nom`)
                SELECT SUBSTRING_INDEX(`Artisan`, " & ", 1) FROM ventes_avant.tmp_artisans

                UNION

                SELECT SUBSTRING_INDEX(`Artisan`, " & ", -1) FROM ventes_avant.tmp_artisans
                ;

                -- -----------------------------------------------------------------------------
                -- Table : conclure
                -- -----------------------------------------------------------------------------

                CREATE TABLE `tmp_conclure` AS

                  SELECT `ID`, `Artisan`
                  FROM ventes_avant.moulaga
                ;

                CREATE TABLE `ventes_avant`.`tmp_conclure2` AS

                  SELECT `ID`, SUBSTRING_INDEX(`Artisan`, " & ", 1) AS nom
                  FROM ventes_avant.tmp_conclure

                  UNION ALL

                  SELECT `ID`, SUBSTRING_INDEX(`Artisan`, " & ", -1) AS nom
                  FROM ventes_avant.tmp_conclure
                  WHERE `Artisan` LIKE "% & %"
                ;

                CREATE TABLE `ventes`.`conclure` (

                  `ID_Vente`    INT UNSIGNED NOT NULL,
                  `ID_Artisan`  INT UNSIGNED NOT NULL

                ) ENGINE = InnoDB;

                INSERT INTO ventes.conclure (`ID_Vente`, `ID_Artisan`)
                  SELECT ccl.ID AS ID_Vente, art.ID AS ID_Artisan
                  FROM ventes_avant.tmp_conclure2 AS ccl
                  INNER JOIN ventes.Artisan AS art
                  ON ccl.nom = art.nom
                ;

                -- -----------------------------------------------------------------------------
                -- Deuxième Table vente temporaire
                -- -----------------------------------------------------------------------------

                CREATE TABLE `Moulaga2` AS
                  SELECT `ID`, `Date`, `Objet`, `Pouvoir`, `Decoration`, `Lieu`, `Oo`, `Oa`, `Of`, `Quantite`
                  FROM ventes_avant.moulaga
                ;

                -- -----------------------------------------------------------------------------
                -- Table : Objet
                -- -----------------------------------------------------------------------------

                CREATE TABLE `ventes`.`Objet` (

                  `ID`          INT UNSIGNED AUTO_INCREMENT NOT NULL,
                  `designation` VARCHAR(256) NOT NULL,

                  CONSTRAINT PK_Objet
                    PRIMARY KEY(`ID`)

                ) ENGINE = InnoDB;

                CREATE TABLE `ventes_avant`.`tmp_objet`
                SELECT DISTINCT `objet`
                FROM ventes_avant.moulaga2;

                INSERT INTO `ventes`.`Objet` (`designation`)
                SELECT objet FROM ventes_avant.tmp_objet;

                -- -----------------------------------------------------------------------------
                -- Table : Mois
                -- -----------------------------------------------------------------------------

                CREATE TABLE `ventes`.`Mois` (

                  `ID`          INT UNSIGNED AUTO_INCREMENT NOT NULL,
                  `designation` VARCHAR(100) NOT NULL,
                  `ordre`       TINYINT UNSIGNED NOT NULL,
                  `ID_Dieu`     INT NOT NULL,

                  CONSTRAINT PK_Mois
                    PRIMARY KEY(`ID`)

                ) ENGINE = InnoDB;



                CREATE TABLE `ventes_avant`.`tmp_mois` AS

                  SELECT `Mois`, `Divinité fétée` AS Party, God.ID
                  FROM ventes_avant.mois AS Month
                  INNER JOIN ventes.Dieu AS God
                  ON Month.`Divinité fétée` = God.nom
                ;

                INSERT INTO `ventes`.`Mois` (`designation`, `ID_Dieu`)
                  SELECT `Mois`, `ID`
                  FROM ventes_avant.tmp_mois
                ;

                UPDATE `mois` SET `ordre` = '1' WHERE `mois`.`ID` = 11;
                UPDATE `mois` SET `ordre` = '2' WHERE `mois`.`ID` = 8;
                UPDATE `mois` SET `ordre` = '3' WHERE `mois`.`ID` = 3;
                UPDATE `mois` SET `ordre` = '4' WHERE `mois`.`ID` = 7;
                UPDATE `mois` SET `ordre` = '5' WHERE `mois`.`ID` = 6;
                UPDATE `mois` SET `ordre` = '6' WHERE `mois`.`ID` = 2;
                UPDATE `mois` SET `ordre` = '7' WHERE `mois`.`ID` = 4;
                UPDATE `mois` SET `ordre` = '8' WHERE `mois`.`ID` = 10;
                UPDATE `mois` SET `ordre` = '9' WHERE `mois`.`ID` = 12;
                UPDATE `mois` SET `ordre` = '10' WHERE `mois`.`ID` = 9;
                UPDATE `mois` SET `ordre` = '11' WHERE `mois`.`ID` = 5;
                UPDATE `mois` SET `ordre` = '12' WHERE `mois`.`ID` = 1;

                -- -----------------------------------------------------------------------------
                -- Table Monnaie
                -- -----------------------------------------------------------------------------

                CREATE TABLE `ventes`.`Monnaie` (

                  `ID`                     INT AUTO_INCREMENT NOT NULL,
                  `designation`            VARCHAR(100) NOT NULL,
                  `abreviation`            VARCHAR(3) NOT NULL,
                  `quantite`               INT NOT NULL,
                  `ID_Monnaie_conversion`  INT NOT NULL,

                  CONSTRAINT PK_Monnaie
                    PRIMARY KEY(`ID`)

                ) ENGINE = InnoDB;


                INSERT INTO ventes.monnaie(`designation`, `quantite`, `abreviation`, `ID_Monnaie_conversion`)
                  SELECT `Monnaie`, `Conversion`, `Monnaie de conversion`, 5
                  FROM ventes_avant.Monnaie
                ;

                -- -----------------------------------------------------------------------------
                -- Table : Lieu
                -- -----------------------------------------------------------------------------

                CREATE TABLE `ventes`.`Lieu` (

                  `ID`          INT UNSIGNED NOT NULL,
                  `designation` VARCHAR(256) NOT NULL,
                  `ID_Province` INT UNSIGNED,

                  CONSTRAINT PK_Lieu
                    PRIMARY KEY(`ID`)

                ) ENGINE = InnoDB ;


                CREATE TABLE `ventes`.`tmp_Lieu` (

                  `ID`          INT UNSIGNED AUTO_INCREMENT NOT NULL,
                  `designation` VARCHAR(256) NOT NULL,

                ) ENGINE = InnoDB ;

                INSERT INTO `ventes`.`tmp_Lieu`(`designation`)
                  SELECT CONCAT_WS(" ", `Province`, `Ville`)
                  FROM ventes_avant.province
                ;

                CREATE TABLE `ventes`.`tmp_lieu2` AS
                  SELECT *, SUBSTRING_INDEX(`designation`, " ", 1) AS province
                  FROM ventes.tmp_lieu
                ;

                CREATE TABLE `ventes`.`tmp_lieu3` AS
                  SELECT tmp_lieu2.ID, SUBSTRING_INDEX(tmp_lieu2.designation, " ", -1) AS `designation`, tmp_Lieu.ID AS `ID_province`
                  FROM ventes.tmp_lieu2
                  LEFT JOIN ventes.tmp_lieu
                  ON tmp_lieu2.province = tmp_lieu.designation
                ;

                INSERT INTO ventes.lieu (`ID`, `designation`, `ID_Province`)
                  SELECT ID, designation , ID_Province
                  FROM ventes.tmp_lieu3
                ;

                UPDATE ventes.lieu SET id_province = NULL
                WHERE ID = ID_Province;


                ALTER TABLE `ventes`.`lieu`
                  MODIFY `ID` INT UNSIGNED AUTO_INCREMENT NOT NULL
                ;

                DROP TABLE `ventes`.`tmp_lieu`;
                DROP TABLE `ventes`.`tmp_lieu2`;
                DROP TABLE `ventes`.`tmp_lieu3`;

                -- -----------------------------------------------------------------------------
                -- Table : inspirer
                -- -----------------------------------------------------------------------------

                CREATE TABLE ventes_avant.`tmp_inspirer` AS
                  SELECT DISTINCT `pouvoir`, `Decoration`
                  FROM ventes_avant.moulaga2
                ;

                CREATE TABLE ventes_avant.`tmp_inspirer2` AS
                  SELECT pouvoir, SUBSTRING_INDEX(decoration, " & ", 1) AS Deco
                  FROM ventes_avant.tmp_inspirer
                  WHERE decoration LIKE "% & %"

                  UNION

                  SELECT pouvoir, SUBSTRING_INDEX(decoration, " & ", -1) AS Deco
                  FROM ventes_avant.tmp_inspirer
                  WHERE decoration LIKE "% & %"

                  UNION

                  SELECT pouvoir, decoration
                  FROM ventes_avant.tmp_inspirer
                  WHERE decoration NOT LIKE "% & %"
                ;

                DELIMITER |
                DROP FUNCTION IF EXISTS ventes_avant.SF_split|

                CREATE FUNCTION ventes_avant.SF_split (
                  Decorazion  VARCHAR(256),
                  Choice      TINYINT
                ) RETURNS VARCHAR(256)

                BEGIN

                DECLARE TheExit   VARCHAR(256);
                DECLARE DecoName  VARCHAR(256);
                DECLARE GodName   VARCHAR(256);
                DECLARE done      INT DEFAULT FALSE;

                DECLARE CurGod CURSOR FOR SELECT  `nom` FROM ventes.Dieu;
                DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
                OPEN CurGod;

                LaBoucle: LOOP
                  FETCH CurGod INTO GodName;
                  IF done THEN
                    LEAVE LaBoucle;

                  ELSEIF (Decorazion LIKE CONCAT("%",GodName,"%")) THEN
                    IF (Choice = 2) THEN
                      SET TheExit = GodName;

                    ELSEIF (Choice = 1) THEN
                      SET DecoName = SUBSTRING_INDEX(Decorazion, GodName, 1);

                      IF (DecoName LIKE "% d'") THEN
                        SET TheExit = SUBSTRING_INDEX(DecoName, " d'", 1);

                      ELSEIF (DecoName LIKE "% de " AND DecoName NOT LIKE "% de % de ") THEN
                        SET TheExit = SUBSTRING_INDEX(DecoName, " de", 1);

                      ELSEIF (DecoName LIKE "% de % de ") THEN
                        SET TheExit = SUBSTRING_INDEX(DecoName, " de", 2);

                      ELSE
                        SET TheExit = "je n'existe pas";

                      END IF;

                    ELSE
                      SET TheExit = "Error : 2nd argument is incorrect";

                    END IF;

                  END IF;

                  END LOOP LaBoucle;
                  CLOSE CurGod;
                  RETURN TRIM(TheExit);
                END|

                CREATE TABLE `tmp_inspirer3` AS
                  SELECT inspired.*, dto.ID AS ID_Deco, beerus.ID AS ID_Dieu, powa.ID AS ID_powa
                  FROM (
                    SELECT Pouvoir,SF_split(Deco, 1) AS decorazion, SF_split(Deco, 2) AS God
                    FROM ventes_avant.tmp_inspirer2
                  ) AS inspired
                  LEFT JOIN ventes.option AS dto
                  ON inspired.decorazion = dto.designation
                  LEFT JOIN ventes.dieu AS beerus
                  ON inspired.God = beerus.nom
                  LEFT JOIN ventes.option AS powa
                  ON inspired.pouvoir = powa.designation
                ;


                SELECT * FROM ventes.Dieu
                WHERE nom LIKE "Kronos"; -- > 11

                UPDATE `tmp_inspirer3`
                SET `ID_Dieu` = 11
                WHERE pouvoir = "Appétit de Kronos";

                -- -----------------------------------------------------------------------------
                CREATE TABLE ventes.`inspirer` (

                  `ID_Option` INT UNSIGNED NOT NULL,
                  `ID_Dieu`   INT UNSIGNED NOT NULL

                ) ENGINE = InnoDB;

                INSERT INTO ventes.inspirer (ID_Option, ID_Dieu)
                  SELECT ID_Deco, ID_Dieu
                  FROM ventes_avant.tmp_inspirer3
                  WHERE ID_Deco IS NOT NULL

                  UNION

                  SELECT ID_powa, ID_Dieu
                  FROM ventes_avant.tmp_inspirer3
                  WHERE ID_powa IS NOT NULL AND ID_Dieu IS NOT NULL
                ;

                -- -----------------------------------------------------------------------------
                -- Table : optionner
                -- -----------------------------------------------------------------------------
                CREATE TABLE `ventes_avant`.`tmp_optionner` AS
                  SELECT ID, pouvoir
                  FROM ventes_avant.moulaga2
                  WHERE pouvoir NOT LIKE ""
                ;

                CREATE TABLE `ventes_avant`.`tmp_optionner2` AS
                  SELECT ID, SUBSTRING_INDEX(decoration, " &", 1) AS Deco
                  FROM ventes_avant.moulaga2
                  WHERE decoration NOT LIKE ""

                  UNION ALL

                  SELECT ID, SUBSTRING_INDEX(decoration, "& ", -1)
                  FROM ventes_avant.moulaga2
                  WHERE decoration NOT LIKE ""
                  AND decoration LIKE "%&%"
                ;


                -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                CREATE TABLE ventes_avant.tmp_optionner3 (

                  `ID_vente`     INT UNSIGNED NOT NULL,
                  `designation`  VARCHAR(256) NOT NULL

                );

                INSERT INTO ventes_avant.tmp_optionner3 (ID_vente, designation)
                  SELECT ID, SF_split(Deco, 1) AS decorazion
                  FROM ventes_avant.tmp_optionner2
                ;

                -- à faire sur invite de commande car très lourd
                -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

                CREATE TABLE ventes.`optionner` (
                  `ID_Vente`  INT UNSIGNED NOT NULL,
                  `ID_Option` INT UNSIGNED NOT NULL

                ) ENGINE = InnoDB;

                INSERT INTO ventes.optionner (ID_Vente, ID_Option)
                  SELECT ID_Vente, table2.ID AS ID_Option FROM (
                    SELECT ID_Vente, designation FROM ventes_avant.tmp_optionner3
                    UNION
                    SELECT ID, pouvoir FROM ventes_avant.tmp_optionner
                  ) AS table1
                  INNER JOIN ventes.option AS table2
                  ON table1.designation = table2.designation
                ;


                -- -----------------------------------------------------------------------------
                -- Table : valoriser
                -- -----------------------------------------------------------------------------

                CREATE TABLE ventes_avant.tmp_valoriser AS
                  SELECT ID AS ID_Vente, 1 AS ID_Monnaie, `Oo` AS Quantite
                  FROM ventes_avant.Moulaga2
                  WHERE `Oo` <> 0
                ;
                CREATE TABLE ventes_avant.tmp_valoriser2 AS
                  SELECT ID AS ID_Vente, 2 AS ID_Monnaie, `Oa` AS Quantite
                  FROM ventes_avant.Moulaga2
                  WHERE `Oa` <> 0
                ;
                CREATE TABLE ventes_avant.tmp_valoriser3 AS
                  SELECT ID AS ID_Vente, 3 AS ID_Monnaie, moulaga2.`Of` AS Quantite
                  FROM ventes_avant.Moulaga2
                  WHERE `Of` <> 0
                ;

                -- -----------------------------------------------------------------------------

                CREATE TABLE ventes.`valoriser` (

                  `ID_Vente`          INT UNSIGNED NOT NULL,
                  `ID_Monnaie`        INT NOT NULL,
                  `quantite_monnaie`  INT UNSIGNED NOT NULL

                ) ENGINE = InnoDB;

                INSERT INTO ventes.valoriser(ID_Vente, ID_Monnaie, quantite_monnaie)
                  SELECT ID_Vente, ID_Monnaie, Quantite
                  FROM ventes_avant.tmp_valoriser

                  UNION

                  SELECT ID_Vente, ID_Monnaie, Quantite
                  FROM ventes_avant.tmp_valoriser2

                  UNION

                  SELECT ID_Vente, ID_Monnaie, Quantite
                  FROM ventes_avant.tmp_valoriser3
                ;

                -- -----------------------------------------------------------------------------
                -- Table : moulaga3
                -- -----------------------------------------------------------------------------

                CREATE TABLE ventes_avant.moulaga3 AS
                  SELECT ID, `Date`, Objet, Pouvoir, Decoration, Lieu, Quantite
                  FROM ventes_avant.Moulaga2
                ;

                -- -----------------------------------------------------------------------------
                -- Table : Vente
                -- -----------------------------------------------------------------------------

                -- Relier aux Dieux-------------------------------------------------------------

                -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                CREATE TABLE ventes_avant.tmp_vente AS
                  SELECT ID, SF_split(decoration, 2) AS DecoDieu
                  FROM ventes_avant.moulaga3
                  WHERE (decoration NOT LIKE "" AND pouvoir LIKE "")
                  OR (decoration NOT LIKE "" AND pouvoir NOT LIKE "")
                ; -- invite de commande
                -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

                SELECT tablea.ID AS ID_Vente, tableb.ID AS ID_Dieu
                FROM ventes_avant.tmp_vente AS tablea
                INNER JOIN ventes.Dieu AS tableb
                ON tablea.decodieu = tableb.nom


                CREATE TABLE ventes_avant.tmp_vente2 AS
                  SELECT ID, pouvoir
                  FROM ventes_avant.moulaga3
                  WHERE pouvoir NOT LIKE "" AND decoration LIKE ""
                ;


                CREATE TABLE ventes_avant.tmp_vente3 AS
                  SELECT tablea.ID AS ID_Vente, tableb.ID AS ID_Dieu
                  FROM ventes_avant.tmp_vente AS tablea
                  INNER JOIN ventes.Dieu AS tableb
                  ON tablea.decodieu = tableb.nom

                  UNION

                  SELECT table1.ID AS ID_Vente, table3.ID_Dieu
                  FROM ventes_avant.tmp_vente2 AS table1
                  INNER JOIN ventes.option AS table2
                  ON table1.pouvoir = table2.designation
                  INNER JOIN ventes.inspirer AS table3
                  ON table2.ID = table3.ID_Option
                ;

                -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                CREATE TABLE ventes_avant.moulaga4 (
                  `ID`        INT UNSIGNED NOT NULL,
                  `Date`      VARCHAR(256) NOT NULL,
                  `Objet`     VARCHAR(256) NOT NULL,
                  `Lieu`      VARCHAR(256) NOT NULL,
                  `Quantite`  INT UNSIGNED NOT NULL,
                  `ID_Dieu`   INT UNSIGNED
                );

                ALTER TABLE ventes_avant.moulaga3
                  ADD INDEX moulaga3(`ID`)
                ;

                ALTER TABLE ventes_avant.tmp_vente3
                  ADD INDEX tmp_vente3(`ID_Vente`)
                ;


                INSERT INTO ventes_avant.moulaga4 (`ID`, `Date`, `Objet`, `Lieu`, `Quantite`, `ID_Dieu`)
                  SELECT table1.ID, table1.Date, table1.Objet, table1.Lieu, table1.Quantite, table2.ID_Dieu
                  FROM ventes_avant.moulaga3 AS table1
                  LEFT JOIN ventes_avant.tmp_vente3 AS table2
                  ON table1.ID = table2.ID_Vente
                ; -- invite de commande
                -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

                -- Relier Objet-----------------------------------------------------------------

                CREATE TABLE ventes_avant.moulaga5 (
                  `ID`        INT UNSIGNED NOT NULL,
                  `Date`      VARCHAR(256) NOT NULL,
                  `Lieu`      VARCHAR(256) NOT NULL,
                  `Quantite`  INT UNSIGNED NOT NULL,
                  `ID_Dieu`   INT UNSIGNED,
                  `ID_Objet`  INT UNSIGNED NOT NULL
                );

                ALTER TABLE ventes_avant.moulaga4
                  ADD INDEX moulaga4(`ID`)
                ;

                INSERT INTO ventes_avant.moulaga5 (`ID`, `Date`, `Lieu`, `Quantite`, `ID_Dieu`, `ID_Objet`)
                  SELECT table1.`ID`, `Date`, `Lieu`, `Quantite`, `ID_Dieu`, table2.ID AS ID_Objet
                  FROM ventes_avant.moulaga4 AS table1
                  INNER JOIN ventes.Objet AS table2
                  ON table1.Objet = table2.designation
                ;

                -- Relier Lieu et demidieu------------------------------------------------------


                ALTER TABLE ventes_avant.moulaga5
                  ADD INDEX DemiLieu(`lieu`)
                ;

                CREATE TABLE ventes_avant.relierlieu1 AS
                  SELECT table1.ID, table2.ID AS ID_Lieu FROM (
                    SELECT ID, `Date`, TRIM(SUBSTRING_INDEX(Lieu, "- ", -1)) AS lieu,
                      Quantite, ID_Dieu, ID_Objet
                    FROM ventes_avant.moulaga5
                  ) AS table1
                  INNER JOIN  ventes.lieu AS table2
                  ON table1.Lieu = table2.designation
                ;

                CREATE TABLE ventes_avant.relierlieu2 AS
                  SELECT table3.ID, table4.ID AS ID_DemiDieu FROM (
                    SELECT ID, `Date`, SUBSTRING(SUBSTRING_INDEX(lieu, " ", -1) FROM 2) AS DD,
                      Quantite, ID_Dieu, ID_Objet
                    FROM ventes_avant.moulaga5
                    WHERE lieu LIKE "Demi Dieu%"
                  ) AS table3
                  LEFT JOIN ventes.DemiDieu AS table4
                  ON table3.DD = table4.nom
                ;

                ALTER TABLE ventes_avant.moulaga5
                  ADD INDEX moulaga5(`ID`)
                ;

                ALTER TABLE ventes_avant.relierlieu1
                  ADD INDEX relierlieu1(`ID`)
                ;
                ALTER TABLE ventes_avant.relierlieu2
                  ADD INDEX relierlieu2(`ID`)
                ;

                CREATE TABLE ventes_avant.moulaga6 (
                  `ID`          INT UNSIGNED NOT NULL,
                  `Date`        VARCHAR(256) NOT NULL,
                  `Quantite`    INT UNSIGNED NOT NULL,
                  `ID_Dieu`     INT UNSIGNED,
                  `ID_Objet`    INT UNSIGNED NOT NULL,
                  `ID_Lieu`     INT UNSIGNED,
                  `ID_DemiDieu` INT UNSIGNED
                );

                INSERT INTO ventes_avant.moulaga6 (`ID`, `Date`, `Quantite`, `ID_Dieu`, `ID_Objet`, `ID_Lieu`, `ID_DemiDieu`)
                  SELECT table1.ID, `Date`, Quantite, ID_Dieu, ID_Objet, table2.ID_Lieu, table3.ID_DemiDieu
                  FROM ventes_avant.moulaga5 AS table1
                  LEFT JOIN ventes_avant.relierlieu1 AS table2
                  ON table1.ID = table2.ID
                  LEFT JOIN ventes_avant.relierlieu2 AS table3
                  ON table1.ID = table3.ID
                ;

                -- Décomposition de la date et finalisation de la table vente-------------------


                CREATE TABLE ventes.`Vente` (
                  `ID`              INT UNSIGNED NOT NULL,
                  `jour`            DECIMAL(2,0) NOT NULL,
                  `annee`           DECIMAL(3,0) NOT NULL,
                  `siecle`          DECIMAL(1,0) NOT NULL DEFAULT 0,
                  `quantite_objet`  INT UNSIGNED NOT NULL,
                  `ID_Objet`        INT UNSIGNED NOT NULL,
                  `ID_Mois`         INT UNSIGNED NOT NULL,
                  `ID_DemiDieu`     INT UNSIGNED,
                  `ID_Lieu`         INT UNSIGNED,
                  `ID_Dieu`         INT,

                  CONSTRAINT PK_Vente
                    PRIMARY KEY(`ID`)
                ) ENGINE = InnoDB;

                INSERT INTO ventes.vente (`ID`, `annee`, `jour`, `quantite_objet`,
                `ID_Dieu`, `ID_Objet`, `ID_Lieu`, `ID_DemiDieu`, `ID_Mois`)
                  SELECT table1.ID, annee, jour, quantite, table1.id_dieu, id_objet,
                    id_lieu, ID_DemiDieu, table2.ID AS `ID_Mois` FROM (
                    SELECT ID, SUBSTRING_INDEX(`Date`, ",", 1) AS annee,
                      SUBSTRING_INDEX(SUBSTRING_INDEX(`Date`, " ", 2), " ", -1) AS mois,
                      SUBSTRING_INDEX(`Date`, " ", -1) AS jour,
                      Quantite, ID_Dieu, ID_Objet, ID_Lieu, ID_DemiDieu
                    FROM ventes_avant.moulaga6
                  ) AS table1
                  INNER JOIN ventes.mois AS table2
                  ON table1.mois = table2.designation
                ;

                ALTER TABLE ventes.vente
                  MODIFY `ID` INT UNSIGNED AUTO_INCREMENT NOT NULL
                ;

                UPDATE ventes.vente SET siecle = 1
                WHERE annee BETWEEN 0 AND 99;

                UPDATE ventes.vente SET siecle = 2
                WHERE annee BETWEEN 100 AND 199;

                UPDATE ventes.vente SET siecle = 3
                WHERE annee BETWEEN 200 AND 299;

                UPDATE ventes.vente SET siecle = 4
                WHERE annee BETWEEN 300 AND 399;

                UPDATE ventes.vente SET siecle = 5
                WHERE annee BETWEEN 400 AND 499;

                -- -----------------------------------------------------------------------------
                -- Mise en place des relations
                -- -----------------------------------------------------------------------------

                SET AUTOCOMMIT = 0;
                START TRANSACTION;

                ALTER TABLE ventes.conclure
                  ADD CONSTRAINT FK_conclure_Vente
                    FOREIGN KEY (`ID_Vente`) REFERENCES vente(`ID`),
                  ADD CONSTRAINT FK_conclure_Artisan
                    FOREIGN KEY (`ID_Artisan`) REFERENCES Artisan(`ID`)
                ;


                ALTER TABLE ventes.demidieu
                  ADD CONSTRAINT FK_DemiDieu_Dieu
                    FOREIGN KEY (`ID_Dieu`) REFERENCES Dieu(`ID`)
                ;

                ALTER TABLE ventes.guerre
                  ADD CONSTRAINT FK_Guere_DemiDieu
                    FOREIGN KEY (`ID_DemiDieu`) REFERENCES DemiDieu(`ID`),
                  ADD CONSTRAINT FK_Guerre_Lieu
                    FOREIGN KEY (`ID_Lieu`) REFERENCES Lieu(`ID`)
                ;

                ALTER TABLE ventes.inspirer
                  ADD CONSTRAINT FK_inspirer_Dieu
                    FOREIGN KEY (`ID_Dieu`) REFERENCES Dieu(`ID`),
                  ADD CONSTRAINT FK_inspirer_Option
                    FOREIGN KEY (`ID_Option`) REFERENCES `Option`(`ID`)
                ;

                ALTER TABLE ventes.lieu
                  ADD CONSTRAINT FK_Lieu_Province
                    FOREIGN KEY (`ID_Province`) REFERENCES Lieu(`ID`)
                ;

                ALTER TABLE ventes.mois
                  ADD CONSTRAINT FK_Mois_Dieu
                    FOREIGN KEY (`ID_Dieu`) REFERENCES Dieu(`ID`)
                ;

                ALTER TABLE ventes.monnaie
                  ADD CONSTRAINT FK_Monnaie_Monnaie_conversion
                    FOREIGN KEY (`ID_Monnaie_conversion`) REFERENCES Monnaie(`ID`)
                ;

                ALTER TABLE ventes.option
                  ADD CONSTRAINT FK_Option_Type_Option
                    FOREIGN KEY (`ID_Type_Option`) REFERENCES Type_Option(`ID`)
                ;

                ALTER TABLE ventes.optionner
                  ADD CONSTRAINT FK_optionner_Vente
                    FOREIGN KEY (`ID_Vente`) REFERENCES Vente(`ID`),
                  ADD CONSTRAINT FK_optionner_Option
                    FOREIGN KEY (`ID_Option`) REFERENCES `Option`(`ID`)
                ;


                ALTER TABLE ventes.valoriser
                  ADD CONSTRAINT FK_valoriser_Vente
                    FOREIGN KEY (`ID_Vente`) REFERENCES Vente(`ID`),
                  ADD CONSTRAINT FK_valoriser_Monnaie
                    FOREIGN KEY (`ID_Monnaie`) REFERENCES Monnaie(`ID`)
                ;

                -- tmp-----------------------------------------------------------------------
                ALTER TABLE ventes.valoriser
                DROP FOREIGN KEY FK_valoriser_Vente,
                DROP FOREIGN KEY FK_valoriser_Monnaie;
                -- --------------------------------------------------------------

                ALTER TABLE ventes.vente
                  ADD CONSTRAINT FK_Vente_Objet
                    FOREIGN KEY (`ID_Objet`) REFERENCES Objet(`ID`),
                  ADD CONSTRAINT FK_Vente_Mois
                    FOREIGN KEY (`ID_Mois`) REFERENCES Mois(`ID`),
                  ADD CONSTRAINT FK_Vente_DemiDieu
                    FOREIGN KEY (`ID_DemiDieu`) REFERENCES DemiDieu(`ID`),
                  ADD CONSTRAINT FK_Vente_Lieu
                    FOREIGN KEY (`ID_Lieu`) REFERENCES Lieu(`ID`),
                  ADD CONSTRAINT FK_Vente_Dieu
                    FOREIGN KEY (`ID_Dieu`) REFERENCES Dieu(`ID`)
                ;

                COMMIT;

                -- -----------------------------------------------------------------------------
                -- Triggers et table Erreur
                -- -----------------------------------------------------------------------------

                CREATE TABLE YFANSI.`Erreur`(

                  `ID`          INT AUTO_INCREMENT NOT NULL,
                  `description` VARCHAR(512) NOT NULL,

                  CONSTRAINT PK_Erreur
                    PRIMARY KEY(`ID`),
                  CONSTRAINT UC_description
                    UNIQUE(`description`)

                ) ENGINE = InnoDB;

                INSERT INTO YFANSI.Erreur(`description`)
                VALUES("There can't be more than 2 craftpersons per sale."),
                      ("There can't be more than 2 decoration per sale."),
                      ("There can't be more than 1 power per sale."),
                      ("Decorations and power must be inspired by the same god for each sale."),
                      ("A sale can't be linked with both place and demigod."),
                      ("That sale is a sponsor so no money is required.")
                ;

                -- -----------------------------------------------------------------------------
                DELIMITER |

                DROP TRIGGER IF EXISTS before_insert_conclure|

                CREATE TRIGGER before_insert_conclure BEFORE INSERT
                ON YFANSI.conclure FOR EACH ROW

                BEGIN

                DECLARE LaVente INT(11) UNSIGNED;
                DECLARE NbArtisans TINYINT;

                SET LaVente = NEW.ID_Vente;

                SELECT COUNT(*) INTO NbArtisans
                FROM YFANSI.conclure
                WHERE ID_Vente = LaVente
                GROUP BY ID_Vente;

                IF (NbArtisans = 2) THEN

                  INSERT INTO YFANSI.erreur(description)
                  VALUES
                    ("There can't be more than 2 craftpersons per sale.");

                END IF;

                END|


                INSERT INTO conclure (ID_Vente, ID_Artisan)
                VALUES (19, 58); -- test

                -- -----------------------------------------------------------------------------

                DELIMITER |

                DROP TRIGGER IF EXISTS LimitDecoPower|

                CREATE TRIGGER LimitDecoPower BEFORE INSERT
                ON YFANSI.optionner FOR EACH ROW

                BEGIN

                DECLARE LaVente  INT(11) UNSIGNED;
                DECLARE LaOption INT(11) UNSIGNED;
                DECLARE LeType   VARCHAR(100);
                DECLARE NbOption TINYINT;

                SET LaOption = NEW.ID_Option;
                SET LaVente  = NEW.ID_Vente;

                SELECT Type_Option.designation INTO LeType
                FROM YFANSI.Option
                INNER JOIN YFANSI.Type_Option
                ON Option.ID_Type_Option = Type_Option.ID
                WHERE Option.ID = LaOption;

                IF (LeType = "décoration") THEN

                  SELECT COUNT(*) INTO NbOption
                  FROM YFANSI.optionner
                  INNER JOIN YFANSI.Option
                  ON optionner.ID_Option = Option.ID
                  INNER JOIN YFANSI.Type_Option
                  ON Option.ID_Type_Option = Type_Option.ID
                  WHERE ID_Vente = LaVente AND Type_Option.ID = 2
                  GROUP BY ID_vente;

                  IF (NbOption = 2) THEN

                    INSERT INTO YFANSI.Erreur (`description`)
                    VALUES("There can't be more than 2 decoration per sale.");

                  END IF;

                ELSEIF (LeType = "pouvoir") THEN

                  SELECT COUNT(*) INTO NbOption
                  FROM YFANSI.optionner
                  INNER JOIN YFANSI.Option
                  ON optionner.ID_Option = Option.ID
                  INNER JOIN YFANSI.Type_Option
                  ON Option.ID_Type_Option = Type_Option.ID
                  WHERE ID_Vente = LaVente AND Type_Option.ID = 1
                  GROUP BY ID_vente;

                  IF (NbOption = 1) THEN

                    INSERT INTO YFANSI.Erreur (`description`)
                    VALUES("There can't be more than 1 power per sale.");

                  END IF;

                END IF;

                END|

                INSERT INTO YFANSI.optionner (ID_Vente, ID_Option)
                VALUES(1, 2); -- test

                INSERT INTO YFANSI.optionner (ID_Vente, ID_Option)
                VALUES(2, 75); -- test

                -- -----------------------------------------------------------------------------

                DELIMITER |

                DROP TRIGGER IF EXISTS MMDieu|

                CREATE TRIGGER MMDieu BEFORE INSERT
                ON YFANSI.optionner FOR EACH ROW

                BEGIN

                DECLARE LaOption INT(11) UNSIGNED;
                DECLARE LeDieu   VARCHAR(256);
                DECLARE LaVente  INT(11) UNSIGNED;

                SET LaVente  = NEW.ID_Vente;
                SET LaOption = NEW.ID_Option;

                SELECT ID_Dieu INTO LeDieu
                FROM YFANSI.vente
                WHERE ID = LaVente;


                IF (LaOption NOT IN
                    (SELECT ID_Option FROM YFANSI.inspirer WHERE ID_Dieu = LeDieu)
                ) THEN

                  INSERT INTO YFANSI.Erreur (`description`)
                  VALUES("Decorations and power must be inspired by the same god for each sale.");


                END IF;

                END|

                INSERT INTO YFANSI.optionner (ID_Vente, ID_Option)
                VALUES(1, 82); -- test

                -- -----------------------------------------------------------------------------

                DELIMITER |

                DROP TRIGGER IF EXISTS PlaceOrDemigod|

                CREATE TRIGGER PlaceOrDemigod BEFORE INSERT
                ON YFANSI.vente FOR EACH ROW

                BEGIN

                DECLARE LeLieu      INT(11) UNSIGNED;
                DECLARE LeDemiDieu  INT(11) UNSIGNED;

                SET LeLieu     = NEW.ID_Lieu;
                SET LeDemiDieu = NEW.ID_DemiDieu;

                IF (LeLieu IS NOT NULL AND LeDemiDieu IS NOT NULL) THEN

                  INSERT INTO YFANSI.Erreur (`description`)
                  VALUES("A sale can't be linked with both place and demigod.");

                END IF;

                END|

                -- -----------------------------------------------------------------------------

                DELIMITER |

                DROP TRIGGER IF EXISTS DemigodOrMoney|

                CREATE TRIGGER DemigodOrMoney BEFORE INSERT
                ON YFANSI.valoriser FOR EACH ROW

                BEGIN

                DECLARE LaVente      INT(11) UNSIGNED;
                DECLARE LeDemiDieu   INT(11) UNSIGNED;

                SET LaVente    = NEW.ID_Vente;

                SELECT ID_DemiDieu INTO LeDemiDieu
                FROM YFANSI.vente
                WHERE ID = LaVente;

                IF (LeDemiDieu IS NOT NULL) THEN

                  INSERT INTO YFANSI.Erreur (`description`)
                  VALUES("That sale is a sponsor so no money is required.");

                END IF;

                END|

                -- -----------------------------------------------------------------------------
