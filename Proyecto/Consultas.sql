
/* CONSULTAS */
	
-- Consulta 1: Partidos ganados por Jugador

-- Masculino
SELECT j.Nombre , j.Apellidos , COUNT(ID_Jug_Ganador) as ganados
FROM Partido_Individual_Masculino p 
INNER JOIN Jugador j
ON p.ID_Jug_Ganador = j.ID_Jugador 
GROUP BY j.Nombre , j.Apellidos 
ORDER BY ganados DESC ;

-- Femenino
SELECT j.Nombre , j.Apellidos , COUNT(*) partidos_ganados
FROM Partido_Individual_Femenino pif 
INNER JOIN Jugador j 
ON pif.ID_Jug_Ganador = j.ID_Jugador 
GROUP BY j.Nombre , j.Apellidos 
ORDER BY COUNT(*) DESC ;


-- Consulta 2: Nombres de los jugadores y partido mas largo de 2020

SELECT j.Nombre , j.Apellidos , j2.Nombre , j2.Apellidos , Duracion 
FROM Partido_Individual_Masculino p
INNER JOIN Jugador j
ON p.ID_Jug_Ganador = j.ID_Jugador 
INNER JOIN Jugador j2
ON p.ID_Jug_Perdedor = j2.ID_Jugador 
WHERE Duracion = (
	SELECT MAX(Duracion)
	FROM Partido_Individual_Masculino p2
	);


-- Consulta 3: Partidos agrupados por el número de sets

SELECT LENGTH(Resultado) - LENGTH(REPLACE(Resultado, '-','')) as num_sets , COUNT(*) 
FROM Partido_Individual_Masculino pim 
GROUP BY num_sets 
ORDER BY 2 DESC ;


-- Consulta 4: Jugadoras femeninas agrupadas por su nacionalidad y que han ganado algún partido

SELECT j.Nacionalidad , COUNT(*) 
FROM Partido_Individual_Femenino pif 
INNER JOIN Jugador j 
ON pif.ID_Jug_Ganador = j.ID_Jugador 
GROUP BY j.Nacionalidad 
ORDER BY 2 DESC ;


-- Consulta 5: Partidos en los que ha habido algún rosco (6-0 o 0-6)

SELECT *
FROM Partido_Individual_Masculino pim 
WHERE pim.Resultado LIKE '%6-0%' OR pim.Resultado LIKE '%0-6%' ;

SELECT *
FROM Partido_Individual_Femenino pif 
WHERE pif.Resultado LIKE '%6-0%' OR pif.Resultado LIKE '%0-6%' ;


/* VISTAS */

-- Vista 1:

CREATE VIEW PartidosGanadosHombres AS
SELECT j.Nombre , j.Apellidos , COUNT(ID_Jug_Ganador) as ganados
FROM Partido_Individual_Masculino p 
INNER JOIN Jugador j
ON p.ID_Jug_Ganador = j.ID_Jugador 
GROUP BY j.Nombre , j.Apellidos 
ORDER BY ganados DESC ;

-- Vista 2:

CREATE VIEW PartidosGanadosMujeres AS
SELECT j.Nombre , j.Apellidos , COUNT(*) ganados
FROM Partido_Individual_Femenino pif 
INNER JOIN Jugador j 
ON pif.ID_Jug_Ganador = j.ID_Jugador 
GROUP BY j.Nombre , j.Apellidos 
ORDER BY COUNT(*) DESC ;

-- Vista 3:

CREATE VIEW PartidosPorSets AS
SELECT LENGTH(Resultado) - LENGTH(REPLACE(Resultado, '-','')) as num_sets , COUNT(*) 
FROM Partido_Individual_Masculino pim 
GROUP BY num_sets 
ORDER BY 2 DESC ;
