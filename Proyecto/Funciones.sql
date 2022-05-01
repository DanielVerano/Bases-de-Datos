/* FUNCIONES, PROCEDIMIENTOS Y TRIGGERS */

-- Función 1: Calcular la ronda máxima que ha ganado un jugador en un torneo y año determinado

DELIMITER $$
CREATE FUNCTION calcularRondaMaxima(codJugador INT, idTorneo INT, anyo INT) RETURNS VARCHAR(5)
DETERMINISTIC

BEGIN
	
	DECLARE ronda VARCHAR(5) DEFAULT '';
	
	SELECT pim.Ronda INTO ronda
	FROM Partido_Individual_Masculino pim 
	WHERE pim.ID_Jug_Ganador = codJugador 
	AND	pim.ID_Torneo = idTorneo 
	AND pim.Año = anyo
	ORDER BY pim.ID_Partido DESC LIMIT 1;

RETURN ronda;

END$$
DELIMITER ;

DROP FUNCTION calcularRondaMaxima ;
SELECT calcularRondaMaxima (104745,2,2020);


-- Función 2: Calcular los puntos que corresponden a una ronda para un torneo

DELIMITER $$ 

CREATE FUNCTION calcularPuntosRonda(idTorneo INT, ronda VARCHAR(5)) RETURNS INT 
DETERMINISTIC 

BEGIN 
	
	DECLARE puntos INT DEFAULT 0;
	DECLARE puntosTorneo INT DEFAULT 0;

	SELECT tt.Puntos INTO puntosTorneo 
	FROM Torneo t 
	INNER JOIN Tipo_Torneo tt 
	ON t.ID_Tipo_Torneo = tt.ID_Tipo_Torneo 
	WHERE t.ID_Torneo = idTorneo ;

	CASE ronda
		WHEN 'F' THEN SET puntos = puntosTorneo ;
		WHEN 'SF' THEN SET puntos = puntosTorneo * 0.6;
		WHEN 'QF' THEN SET puntos = puntosTorneo * 0.36;
		WHEN 'R16' THEN SET puntos = puntosTorneo * 0.18;
		WHEN 'R32' THEN SET puntos = puntosTorneo * 0.09;
		WHEN 'R64' THEN SET puntos = puntosTorneo * 0.045;
		WHEN 'R128' THEN SET puntos = puntosTorneo * 0.0225;
	ELSE
		SET puntos = 0;
	END CASE;

RETURN puntos;
	
END$$ 

DELIMITER ;

SELECT calcularPuntosRonda (19, 'F');


-- Función 3: Calcular los puntos de un jugador


DELIMITER $$ 
CREATE FUNCTION calcularPuntosJugador(codJugador INT) RETURNS INT 
DETERMINISTIC 

BEGIN 
	
	DECLARE salida INT DEFAULT FALSE;
	DECLARE total_puntos INT DEFAULT 0;
	DECLARE torneo_actual INT DEFAULT 0;
	DECLARE ronda_actual VARCHAR(5) DEFAULT '';
	DECLARE cur1 CURSOR FOR 
		SELECT pim.ID_Torneo , calcularRondaMaxima (codJugador, pim.ID_Torneo, pim.AÃ±o)
		FROM Partido_Individual_Masculino pim 
		WHERE pim.ID_Jug_Ganador = codJugador OR pim.ID_Jug_Perdedor = codJugador
		GROUP BY pim.ID_Torneo , pim.AÃ±o
		ORDER BY pim.ID_Torneo ;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET salida = TRUE;

	OPEN cur1;

	leer_cursor: LOOP 
		FETCH cur1 INTO torneo_actual , ronda_actual;
	
		IF (salida) THEN 
			LEAVE leer_cursor;
		END IF;
	
		SET total_puntos = total_puntos + calcularPuntosRonda (torneo_actual, ronda_actual);
	END LOOP;

	CLOSE cur1;

RETURN total_puntos;
	
END$$ 
DELIMITER ;

DROP FUNCTION calcularPuntosJugador ;
SELECT calcularPuntosJugador (104745);


/* PROCEDIMIENTOS */

-- Crear la tabla Rankings que almacena los puntos de cada jugador

CREATE TABLE Rankings AS (
	SELECT j.ID_Jugador 
	FROM Jugador j 
);

ALTER TABLE Rankings ADD FOREIGN KEY (ID_Jugador) REFERENCES Jugador(ID_Jugador);
ALTER TABLE Rankings ADD COLUMN puntos INT DEFAULT 0;

-- Procedimiento 1: Actualizar los rankings de todos los jugadores

DELIMITER $$ 
CREATE PROCEDURE actualizarPuntosJugador()

BEGIN 
	
	UPDATE Rankings
	SET puntos = calcularPuntosJugador (ID_Jugador);
	
END$$
DELIMITER ;

CALL actualizarPuntosJugador ;


-- Procedimiento 2: Insertar ganadores de cada torneo

CREATE TABLE Ganadores (
	id INT PRIMARY KEY AUTO_INCREMENT,
	anyo INT,
	torneo VARCHAR(45),
	nombre VARCHAR(45),
	apellido VARCHAR(45)
);


DELIMITER $$ 
CREATE PROCEDURE insertarGanadores(anyo INT)
BEGIN 
	
	DECLARE salida INT DEFAULT FALSE;
	DECLARE nom_jug VARCHAR(45) DEFAULT '';
	DECLARE apel_jug VARCHAR(45) DEFAULT '';
	DECLARE cod_jug INT DEFAULT 0;
	DECLARE id_torneo INT DEFAULT 0;
	DECLARE nom_torneo VARCHAR(45) DEFAULT '';
	DECLARE cur1 CURSOR FOR
		SELECT pim.ID_Torneo , pim.ID_Jug_Ganador 
		FROM Partido_Individual_Masculino pim 
		WHERE pim.Ronda = 'F'
		ORDER BY pim.ID_Torneo ;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET salida = TRUE;

	OPEN cur1;

	leer_cursor: LOOP 
		FETCH cur1 INTO id_torneo , cod_jug ;
	
		IF (salida) THEN 
			LEAVE leer_cursor;
		END IF;
	
		SELECT t.Nombre INTO nom_torneo 
		FROM Torneo t 
		WHERE t.ID_Torneo = id_torneo ;
	
		SELECT j.Nombre , j.Apellidos INTO nom_jug , apel_jug 
		FROM Jugador j 
		WHERE j.ID_Jugador = cod_jug ;
	
		INSERT INTO Ganadores (anyo, torneo, nombre, apellido)
		VALUES(anyo, nom_torneo, nom_jug, apel_jug);
	END LOOP;

	CLOSE cur1;
	
END$$ 
DELIMITER ;

DROP PROCEDURE insertarGanadores ;
CALL insertarGanadores (2020);


-- Procedimiento 3: Mostrar los enfrentamientos entre dos jugadores

DELIMITER $$ 
CREATE PROCEDURE mostrarEnfrentamientos(jugador1 INT, jugador2 INT)
BEGIN 
	
	SELECT *
	FROM Partido_Individual_Masculino pim 
	WHERE pim.ID_Jug_Ganador IN (jugador1, jugador2) AND
	pim.ID_Jug_Perdedor IN (jugador1, jugador2);
	
END$$ 
DELIMITER ;


DROP PROCEDURE mostrarEnfrentamientos ;
CALL mostrarEnfrentamientos (104745, 104925);


/* TRIGGERS */


-- Trigger 1: Trigger que al insertar un partido compruebe que no pueda haber dos finales para un mismo torneo

DELIMITER $$
CREATE TRIGGER dosFinalesIguales
BEFORE INSERT ON Partido_Individual_Masculino FOR EACH ROW
BEGIN 
	
	DECLARE existe INT DEFAULT FALSE;

	SELECT COUNT(*) INTO existe 
	FROM Partido_Individual_Masculino pim 
	WHERE pim.ID_Torneo = NEW.ID_Torneo AND
	pim.AÃ±o = NEW.AÃ±o AND 
	pim.ronda = 'F';

	IF (existe) THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No pueden haber dos finales para un mismo torneo';
	END IF;
	
END$$ 
DELIMITER ;


INSERT INTO Partido_Individual_Masculino 
VALUES(1702, 'F', 161, 2020, 2, NULL, 104745, 104925, '6-0 6-2 7-5');


-- Trigger 2: Trigger que al insertar un partido incremente las victorias y derrotas de cada jugador

ALTER TABLE Rankings ADD COLUMN victorias INT DEFAULT 0;
ALTER TABLE Rankings ADD COLUMN derrotas INT DEFAULT 0;

DELIMITER $$ 
CREATE TRIGGER actualizarVictoriasYDerrotas
AFTER INSERT ON Partido_Individual_Masculino FOR EACH ROW 
BEGIN 
	
	UPDATE Rankings 
	SET victorias = victorias + 1
	WHERE ID_Jugador = NEW.ID_Jug_Ganador ;

	UPDATE Rankings 
	SET derrotas = derrotas + 1
	WHERE ID_Jugador = NEW.ID_Jug_Perdedor ;
	
END$$ 
DELIMITER ;


INSERT INTO Partido_Individual_Masculino 
VALUES(1702, 'F', 161, 2021, 2, NULL, 104745, 104925, '6-0 6-2 7-5');


