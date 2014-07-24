CREATE DATABASE IF NOT EXISTS eksidebe
	CHARACTER SET utf8 collate utf8_turkish_ci;

USE eksidebe;

CREATE TABLE IF NOT EXISTS Authors(
ID int NOT NULL AUTO_INCREMENT PRIMARY KEY,
Name varchar(255) NOT NULL
)CHARACTER SET utf8 collate utf8_turkish_ci;

CREATE TABLE IF NOT EXISTS Topics(
ID int NOT NULL AUTO_INCREMENT PRIMARY KEY,
Name varchar(255) NOT NULL,
Link varchar(255) NOT NULL
)CHARACTER SET utf8 collate utf8_turkish_ci;

CREATE TABLE IF NOT EXISTS Entries(
ID bigint NOT NULL PRIMARY KEY,
Author int NOT NULL,
Topic int NOT NULL,
Published datetime NOT NULL,
LastEdit datetime,
Accessed datetime NOT NULL,
Body longtext,
Favcount int,
FOREIGN KEY (Author)
	REFERENCES Authors(ID)
	ON UPDATE CASCADE
	ON DELETE RESTRICT,
FOREIGN KEY (Topic)
	REFERENCES Topics(ID)
	ON UPDATE CASCADE
	ON DELETE RESTRICT
)CHARACTER SET utf8 collate utf8_turkish_ci;

CREATE TABLE IF NOT EXISTS DebeEntries(
Day date NOT NULL,
Place int NOT NULL,
Entry bigint NOT NULL,
PRIMARY KEY (Day,Place),
FOREIGN KEY (Entry)
	REFERENCES Entries(ID)
	ON UPDATE CASCADE
	ON DELETE RESTRICT
)CHARACTER SET utf8 collate utf8_turkish_ci;

CREATE TABLE IF NOT EXISTS RefEntries(
DebeEntry bigint NOT NULL,
RefEntry bigint NOT NULL,
PRIMARY KEY (DebeEntry,RefEntry),
FOREIGN KEY (DebeEntry)
	REFERENCES DebeEntries(Entry)
	ON UPDATE CASCADE
	ON DELETE RESTRICT,
FOREIGN KEY (RefEntry)
	REFERENCES Entries(ID)
	ON UPDATE CASCADE
	ON DELETE RESTRICT
)CHARACTER SET utf8 collate utf8_turkish_ci;

CREATE TABLE IF NOT EXISTS Users(
ID int NOT NULL AUTO_INCREMENT PRIMARY KEY,
User varchar(31) NOT NULL,
Pass varchar(127) NOT NULL,
Type ENUM('ADMIN','TEST','SUSER') NOT NULL,
UNIQUE(User)
)CHARACTER SET utf8 collate utf8_turkish_ci;

INSERT INTO `Users`(`ID`, `User`, `Pass`, `Type`) 
VALUES ('1','kyzn','$2y$10$C/RSESqS0D0NRKufO43AmOd7KCL70hxwFwkOsGicsCTCZkeNHOJTm','ADMIN')