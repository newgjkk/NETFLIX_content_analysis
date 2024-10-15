------ NETFLIX PROJECT -------
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix(
	show_id			VARCHAR(10),
	type 			VARCHAR(20),
	title			VARCHAR(150),
	director		VARCHAR(250),
	casts			VARCHAR(1000),
	country			VARCHAR(150),
	date_added		VARCHAR(50),
	release_year	INT,
	rating			VARCHAR(15),
	duration		VARCHAR(15),
	listed_in		VARCHAR(80),
	description		VARCHAR(350)
);

SELECT * FROM netflix;






